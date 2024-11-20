{ pkgs, configs }:

let
  utils = import ./utils.nix { inherit pkgs; };
in
pkgs.writeShellScriptBin "misskey" ''
  # Environment variables
  export NODE_ENV="development"
  export VITE_PORT="5173"
  export EMBED_VITE_PORT="5174"
  export PORT="3000"
  export PGDATA="$(pwd)/data/postgres"
  export PGHOST="localhost"
  export PGUSER="taka"
  export PGDATABASE="misskey"
  export PGPORT="5433"
  export LC_ALL="C"
  export LANG="C"
  export PATH="${pkgs.nodejs_20}/bin:${pkgs.postgresql_15}/bin:${pkgs.redis}/bin:$PATH"

  # Import utility functions
  ${utils.functions}

  setup_postgres() {
    log "Initializing PostgreSQL..."
    pg_ctl -D "$PGDATA" stop 2>/dev/null || true
    sleep 2
    rm -rf "$PGDATA"
    mkdir -p "$PGDATA"
    initdb -D "$PGDATA" --auth=trust --no-locale --encoding=UTF8 || error "Failed to initialize PostgreSQL"
    echo "${configs.postgres.postgresql}" > "$PGDATA/postgresql.conf"
    echo "${configs.postgres.pg_hba}" > "$PGDATA/pg_hba.conf"
    mkdir -p "$PGDATA/log"
    pg_ctl -D "$PGDATA" -l "$PGDATA/log/postgresql.log" start || error "Failed to start PostgreSQL"
    sleep 3
    pg_isready -p 5433 || error "PostgreSQL is not responding"
    createdb -p 5433 misskey || error "Failed to create database"
    success "PostgreSQL initialized"
  }

  setup_redis() {
    log "Initializing Redis..."
    redis-cli shutdown 2>/dev/null || true
    sleep 1
    rm -rf "$(pwd)/data/redis"
    mkdir -p "$(pwd)/data/redis"
    chmod 777 "$(pwd)/data/redis"
    cp ${configs.redis} "$(pwd)/data/redis/redis.conf"
    chmod 644 "$(pwd)/data/redis/redis.conf"
    redis-server "$(pwd)/data/redis/redis.conf" || error "Failed to start Redis"
    sleep 2
    if ! redis-cli ping > /dev/null 2>&1; then
      error "Redis is not responding"
      return 1
    fi
    redis-cli config set save "" > /dev/null 2>&1
    redis-cli config set appendonly no > /dev/null 2>&1
    redis-cli config set stop-writes-on-bgsave-error no > /dev/null 2>&1
    success "Redis initialized"
  }

  setup_config() {
    log "Creating Misskey configuration..."
    mkdir -p .config
    cp ${configs.misskey} .config/default.yml
    success "Configuration created"
  }

  setup() {
    log "Starting setup process..."
    setup_postgres
    setup_redis
    setup_config
    log "Installing dependencies..."
    git submodule update --init || error "Failed to update git submodules"
    pnpm install --frozen-lockfile || error "Failed to install dependencies"
    log "Building Misskey..."
    pnpm build || error "Build failed"
    log "Running migrations..."
    pnpm migrate || error "Migration failed"
    success "Setup completed successfully"
  }

  start() {
    log "Starting development server..."
    if ! pg_isready -p 5433 >/dev/null 2>&1; then
      pg_ctl -D "$PGDATA" -l "$PGDATA/log/postgresql.log" start
    fi
    if ! redis-cli ping >/dev/null 2>&1; then
      redis-server --daemonize yes --dir "$(pwd)/data/redis"
    fi
    mkdir -p data/logs
    log "Starting Vite development servers..."
    (cd packages/frontend && pnpm dev) &
    (cd packages/frontend-embed && pnpm dev) &
    (cd packages/backend && pnpm dev)
  }

  stop() {
    log "Stopping services..."
    pg_ctl -D "$PGDATA" stop 2>/dev/null || true
    redis-cli shutdown 2>/dev/null || true
    success "Services stopped"
  }

  clean() {
    log "Cleaning environment..."
    stop
    rm -rf data/postgres data/redis node_modules .config/default.yml
    success "Environment cleaned"
  }

  # Main command handler
  if [ $# -eq 0 ]; then
    show_help
  fi

  case "''${1:-}" in
    setup) setup ;;
    start) start ;;
    stop) stop ;;
    clean) clean ;;
    reset) clean && setup ;;
    psql) psql -p 5433 misskey ;;
    status)
      pg_isready -p 5433 && echo "PostgreSQL is running" || echo "PostgreSQL is not running"
      redis-cli ping >/dev/null 2>&1 && echo "Redis is running" || echo "Redis is not running"
      ;;
    logs)
      case "''${2:-all}" in
        postgres) tail -f "$PGDATA/log/postgresql.log" ;;
        *) tail -f data/logs/* ;;
      esac
      ;;
    *) show_help ;;
  esac
''
