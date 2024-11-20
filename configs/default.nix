{ pkgs }:

{
  misskey = import ./misskey.nix { inherit pkgs; };
  redis = import ./redis.nix { inherit pkgs; };
  postgres = import ./postgres.nix { inherit pkgs; };
}
