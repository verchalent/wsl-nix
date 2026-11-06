# The shell experience: zsh-prompt, from the zsh-prompt-evolution flake.
{ pkgs, inputs, ... }:
[ inputs.zsh-prompt.packages.${pkgs.stdenv.hostPlatform.system}.default ]
