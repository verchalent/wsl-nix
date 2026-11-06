# tmux with a store config, so nothing is read from or written to ~/.tmux.conf.
# Mirrors the IsildursBane settings.
{ pkgs, inputs, ... }:
let
  zshPrompt = inputs.zsh-prompt.packages.${pkgs.stdenv.hostPlatform.system}.default;
  conf = pkgs.writeText "tmux.conf" ''
    set -g default-command "${zshPrompt}/bin/zsh-prompt --no-zellij"
    set -g default-terminal "screen-256color"
    set -g history-limit 5000
    set -g clock-mode-style 24
    run-shell ${pkgs.tmuxPlugins.better-mouse-mode.rtp}
  '';
in
[
  (pkgs.writeShellScriptBin "tmux" ''
    exec ${pkgs.lib.getExe pkgs.tmux} -f ${conf} "$@"
  '')
]
