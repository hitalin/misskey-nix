{ pkgs }:

pkgs.writeTextFile {
  name = "default.yml";
  text = ''
    url: "http://localhost:3000/"
    port: 3000
    db:
      host: "localhost"
      port: 5433
      db: "misskey"
      user: "postgres"
      pass: "postgres"
    redis:
      host: "localhost"
      port: 6379
    id: "aid"
    vite:
      port: 5173
      embedPort: 5174
  '';
}