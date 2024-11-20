{ pkgs }:

builtins.toFile "redis.conf" ''
  bind 0.0.0.0
  port 6379
  daemonize yes
  dir ./data/redis
  save ""
  appendonly no
  stop-writes-on-bgsave-error no
  maxmemory 512mb
  maxmemory-policy allkeys-lru
  databases 16
  tcp-keepalive 300
  supervised no
  loglevel notice
  logfile ""
  always-show-logo no
''
