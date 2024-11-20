{ pkgs, scripts }:

pkgs.mkShell {
  name = "misskey-dev-shell";

  packages = with pkgs; [
    nodejs_20
    pnpm
    postgresql_15
    redis
    ffmpeg
    python311
    gcc
    meilisearch
    git
    gnumake
    scripts.misskeyEnv
  ];

  shellHook = ''
    echo "🚀 Welcome to Misskey development environment"
    echo
    echo "Type 'misskey' to see available commands"
    echo
    if [ ! -f .config/default.yml ]; then
      echo "🔧 First time? Run 'misskey setup' to initialize the environment"
    fi

    # Only set trap when not using direnv
    if [ -z "$DIRENV_IN_ENVRC" ]; then
      trap 'misskey stop' EXIT
    fi

    # Development environment
    export NODE_ENV="development"
    export VITE_PORT="5173"
    export EMBED_VITE_PORT="5174"
    export PORT="3000"

    # Additional helpful vars
    export DEBUG="*"
    export NODE_OPTIONS="--max-old-space-size=4096"
    export MISSKEY_TRACE="1"
  '';

  # Required for some build processes
  LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";

  # Ensure consistent locale settings
  LANG = "en_US.UTF-8";

  # PostgreSQL settings
  PGDATA = "$(pwd)/data/postgres";
  PGHOST = "localhost";
  PGUSER = "taka";
  PGDATABASE = "misskey";
  PGPORT = "5433";
}
