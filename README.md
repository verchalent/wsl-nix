# wsl-nix

A Nix-defined shell and dev-tools environment for Ubuntu-based WSL2 distros. One script
installs Nix, installs everything in this flake as a Nix profile, and makes the
[zsh-prompt-evolution](https://github.com/verchalent/zsh-prompt-evolution) shell the interactive
shell. That repo owns the shell experience; this one consumes it and adds dev tools.

## Usage

### New system setup (once)

`install.sh` is only for setting up a new distro. On a fresh Ubuntu-based WSL2 distro, as your normal user (it uses `sudo` where needed):

```sh
curl -fsSL https://raw.githubusercontent.com/verchalent/wsl-nix/main/install.sh | bash
```

or from a clone: `./install.sh`. Then open a new terminal; you land in the prompt.

What the script does (safe to re-run if it is interrupted):

1. Installs prerequisites with apt: `curl`, `xz-utils`, `ca-certificates`, `git`.
2. Writes `~/.config/nix/nix.conf` to enable flakes (only if not already set).
3. Installs single-user Nix at a pinned version (`/nix` owned by your user, no daemon, no
   installer edits to your profile).
4. Adds a marked block to `~/.profile` putting `~/.nix-profile/bin` on `PATH`.
5. Installs this flake's environment: `nix profile add github:verchalent/wsl-nix`
   (or `nix profile upgrade --all` when already installed).
6. Adds a marked, interactive-only block to `~/.bashrc` that hands over to `zsh-prompt`.
   It is a hook rather than `chsh`, so scripts and tools that expect a POSIX login shell are
   unaffected. Skip it with `./install.sh --no-shell`; bypass it once with
   `WSL_NIX_NO_PROMPT=1 bash`.

### Everywhere else: `nix run`

On a machine that already has Nix with flakes enabled (including this distro after setup),
don't run the installer. Start the environment directly, with nothing installed or changed:

```sh
nix run github:verchalent/wsl-nix
```

This opens `zsh-prompt` with every tool in this flake on `PATH`.

### Changing what's installed

Edit a module (or the host list) and push. On a set-up system, apply it with
`nix profile upgrade --all`; with `nix run` you always get the latest. Free disk space with
`nixclean` / `nixdeepclean` (below).

## Layout

```
flake.nix        # wiring only: builds one package per environment
hosts/wsl/       # the environment: which modules it uses, which unfree packages it allows
modules/         # reusable pieces; each is { pkgs, inputs, ... }: [ package ... ]
  shell.nix      #   zsh-prompt (from the zsh-prompt-evolution flake)
  dev.nix        #   dev tools
  tmux.nix       #   tmux with a store-managed config
  nix-gc.nix     #   nixclean / nixdeepclean helpers
install.sh       # the single setup script
```

`packages.<system>.default` is the `wsl` environment (`wsl-env`) for `x86_64-linux` and
`aarch64-linux`. To add an environment, add a directory under `hosts/` and list it in
`flake.nix`. Unfree packages are allowed one by one by name (`unfree` in the host file),
never wholesale.

## What's included

**Dev tools** (`modules/dev.nix`)

| Tool | Purpose |
| --- | --- |
| `python3` | Python |
| `uv` | Python package and project manager |
| `lazygit` | Terminal UI for git |
| `lazydocker` | Terminal UI for Docker (needs an engine, see below) |
| `awscli2` | AWS command line |
| `claude-code` | Claude Code CLI (unfree, allowlisted) |

**Shell** (`modules/shell.nix`: the `zsh-prompt` package, which bundles)

| Tool | Purpose |
| --- | --- |
| `zsh`, `starship` | Shell and prompt |
| `git`, `curl` | Basics |
| `hx` | Helix editor, preconfigured |
| `atuin` | Shell history search |
| `tldr` | Short command examples (pages fetched on first use) |
| `ttt` | Workspace helper from the prompt flake |
| `zellij` | Terminal multiplexer |
| `ripgrep`, `fd`, `fzf` | Search |
| `lsd`, `bat` | Better `ls` and `cat` (alias `la` = `lsd -la`) |
| `zoxide` | Smarter `cd` |
| `direnv` | Per-directory environments |
| `pay-respects` | Fix the previous command |
| `procs`, `duf`, `ncdu` | Processes, disks, disk usage |
| `fastfetch` | System summary |

The authoritative list is the prompt flake's `nix/packages.nix`; if it differs from this table,
that file wins.

**Extras**

- `tmux` (`modules/tmux.nix`): wrapper using a config from the Nix store, so nothing is read
  from `~/.tmux.conf`. Default shell is `zsh-prompt`, 256 colours, 5000 lines of history,
  24-hour clock, better mouse mode.
- `nixclean` / `nixdeepclean` (`modules/nix-gc.nix`): `nixclean` drops profile generations
  older than 30 days and collects garbage; `nixdeepclean` drops all but the current generation.

## Not handled here

- **Windows side:** install a Nerd Font and select it in your terminal; terminal colours and
  any SSH agent relay are configured in Windows.
- **Docker engine:** `lazydocker` needs one reachable from WSL (Docker Desktop's WSL
  integration, or docker-ce / podman installed separately). This flake doesn't install it.
- **Credentials:** none live in this repo. Configure AWS and others on the machine, e.g.
  `aws configure sso`.

## Pins

`nixpkgs` and `zsh-prompt` are pinned in `flake.lock`. Bump one input at a time, and only to a
revision at least 8 days old (supply-chain cooldown):

```sh
nix flake lock --override-input nixpkgs github:NixOS/nixpkgs/<rev>
nix flake update zsh-prompt
```
