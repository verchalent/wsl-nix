# Dev tools. (age/sops are deliberately not here; credentials never live in this repo.)
{ pkgs, ... }:
[
  pkgs.python3
  pkgs.uv
  pkgs.lazygit
  pkgs.lazydocker # needs a Docker engine reachable from WSL, see README
  pkgs.awscli2
  # pkgs.claude-code # unfree, see hosts/wsl
]
