{ pkgs }:

builtins.toFile "default.yml" ''
  url: "http://localhost:3000/"
  port: 3000
  db:
    host: "localhost"
    port: 5433
    db: "misskey"
    user: "taka"
    pass: ""
  redis:
    host: "localhost"
    port: 6379
  id: "aid"
  vite:
    port: 5173
    embedPort: 5174
''
