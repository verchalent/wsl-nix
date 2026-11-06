{
  description = "A portable shell and dev-tools environment for Ubuntu-based WSL2, defined as a flake";

  # Pins live in flake.lock. Bump one input at a time, and only to a revision at least
  # 8 days old (supply-chain cooldown, same rule as zsh-prompt-evolution), e.g.:
  #   nix flake lock --override-input nixpkgs github:NixOS/nixpkgs/<rev>
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # The prompt/shell experience lives in its own flake; this repo only consumes it.
    zsh-prompt = {
      url = "github:verchalent/zsh-prompt-evolution";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Wiring only. What goes in an environment lives in hosts/<name>/ and modules/.
  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      # name -> { unfree, modules }; add a directory under hosts/ and list it here.
      hosts = {
        wsl = import ./hosts/wsl;
      };

      mkEnv =
        system: name: host:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) host.unfree;
          };
        in
        pkgs.buildEnv {
          name = "${name}-env";
          paths = lib.concatMap (m: import m { inherit pkgs inputs; }) host.modules;
        };
    in
    {
      # `nix profile add github:verchalent/wsl-nix` installs the default environment;
      # `...#<name>` picks another.
      packages = lib.genAttrs systems (
        system: lib.mapAttrs (mkEnv system) hosts // { default = mkEnv system "wsl" hosts.wsl; }
      );

      # `nix run github:verchalent/wsl-nix` starts zsh-prompt with the whole environment on
      # PATH, without installing anything into a profile.
      apps = lib.genAttrs systems (
        system:
        let
          env = self.packages.${system}.default;
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = {
            type = "app";
            program = lib.getExe (
              pkgs.writeShellScriptBin "wsl-nix" ''
                export PATH="${env}/bin:$PATH"
                exec ${env}/bin/zsh-prompt "$@"
              ''
            );
          };
        }
      );

      formatter = lib.genAttrs systems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
