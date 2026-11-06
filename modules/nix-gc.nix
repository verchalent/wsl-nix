# Single-user Nix only grows; these mirror nixclean/nixdeepclean from
# IsildursBane (without the darwin and home-manager generations, which don't exist here).
# They use the `nix` installed by install.sh.
{ pkgs, ... }:
[
  (pkgs.writeShellScriptBin "nixclean" ''
    echo "==> [1/2] Dropping profile generations older than 30d..."
    nix profile wipe-history --older-than 30d
    echo "==> [2/2] Collecting garbage..."
    nix-collect-garbage
  '')
  (pkgs.writeShellScriptBin "nixdeepclean" ''
    echo "==> [1/2] Dropping every profile generation except the current one..."
    nix profile wipe-history
    echo "==> [2/2] Collecting garbage..."
    nix-collect-garbage -d
  '')
]
