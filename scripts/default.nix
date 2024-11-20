{ pkgs, configs }:

{
  misskeyEnv = import ./misskey-env.nix { inherit pkgs configs; };
}
