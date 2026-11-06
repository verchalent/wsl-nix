#!/usr/bin/env bash
# Set up an Ubuntu-based WSL2 distro: Nix, this flake's environment, and zsh-prompt
# as the interactive shell. Run as your normal user (it uses sudo where needed).
# Safe to re-run: a second run upgrades the environment.
#
#   curl -fsSL https://raw.githubusercontent.com/verchalent/wsl-nix/main/install.sh | bash
#   ./install.sh [--no-shell]     # --no-shell: don't hook zsh-prompt into ~/.bashrc
set -euo pipefail

NIX_VERSION="2.35.4" # pinned installer; bump deliberately
FLAKE="github:verchalent/wsl-nix"
HOOK_SHELL=1

for arg in "$@"; do
  case "$arg" in
    --no-shell) HOOK_SHELL=0 ;;
    -h|--help)  echo "usage: $0 [--no-shell]"; exit 0 ;;
    *)          echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

[ "$(id -u)" -ne 0 ] || { echo "run as your normal user, not root" >&2; exit 1; }
command -v apt-get >/dev/null || { echo "apt-get not found: this targets Ubuntu/Debian-based distros" >&2; exit 1; }

echo "==> Prerequisites (apt)"
sudo apt-get update -qq
sudo apt-get install -y curl xz-utils ca-certificates git

echo "==> Nix config (~/.config/nix/nix.conf)"
mkdir -p "$HOME/.config/nix"
conf="$HOME/.config/nix/nix.conf"
grep -qs '^experimental-features' "$conf" \
  || echo 'experimental-features = nix-command flakes' >> "$conf"

if [ ! -x "$HOME/.nix-profile/bin/nix" ]; then
  echo "==> Installing Nix $NIX_VERSION (single-user, no profile edits)"
  sudo install -d -o "$(id -un)" -g "$(id -gn)" /nix
  curl -fsSL "https://releases.nixos.org/nix/nix-$NIX_VERSION/install" \
    | sh -s -- --no-daemon --no-modify-profile --yes
fi
export PATH="$HOME/.nix-profile/bin:$PATH"

# Put the profile on PATH for login shells (idempotent marker block).
profile="$HOME/.profile"
if ! grep -qs '# >>> wsl-nix path >>>' "$profile"; then
  cat >> "$profile" <<'EOF'
# >>> wsl-nix path >>>
export PATH="$HOME/.nix-profile/bin:$PATH"
# <<< wsl-nix path <<<
EOF
fi

echo "==> Installing the environment from $FLAKE"
if nix profile list 2>/dev/null | grep -q "verchalent/wsl-nix"; then
  nix profile upgrade --all --no-write-lock-file
else
  # --no-write-lock-file: a remote flake cannot be re-locked on the client.
  nix profile add --no-write-lock-file "$FLAKE"
fi

if [ "$HOOK_SHELL" -eq 1 ]; then
  echo "==> Handing interactive shells over to zsh-prompt (~/.bashrc)"
  # An interactive-only hook, not chsh: scripts, ssh commands and tools that expect a
  # POSIX login shell keep working. Escape hatch: WSL_NIX_NO_PROMPT=1 bash
  rc="$HOME/.bashrc"
  if ! grep -qs '# >>> wsl-nix shell >>>' "$rc"; then
    cat >> "$rc" <<'EOF'
# >>> wsl-nix shell >>>
case $- in
  *i*)
    if [ -z "${WSL_NIX_NO_PROMPT:-}" ] && [ -z "${ZSH_PROMPT_STATE:-}" ] \
       && [ -x "$HOME/.nix-profile/bin/zsh-prompt" ]; then
      exec "$HOME/.nix-profile/bin/zsh-prompt"
    fi
    ;;
esac
# <<< wsl-nix shell <<<
EOF
  fi
fi

cat <<'EOF'

==> Done. Open a new terminal (or run `exec bash`).
Windows side, not handled here: install a Nerd Font and select it in Windows Terminal.
lazydocker needs a Docker engine reachable from WSL (see README).
EOF
