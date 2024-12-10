# nix-misskey

This project uses Nix for development environment management.

1. Install Nix: https://nixos.org/download.html

2. Enable flakes:

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

3. Setup development environment:

```bash
git clone --recursive https://github.com/your-username/misskey.git
cd misskey
git submodule add https://github.com/your-username/nix-misskey.git .nix-misskey
git submodule update --init --recursive
nix develop ./.nix-misskey#default
misskey setup
misskey start
```
