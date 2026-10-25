{
  description = "island: a dynamic-island style Quickshell shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAll (pkgs: rec {
        island = pkgs.callPackage ./package.nix { };
        default = island;
      });

      apps = forAll (pkgs: {
        default = {
          type = "app";
          program = nixpkgs.lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.default;
        };
      });

      overlays.default = final: _prev: { island = final.callPackage ./package.nix { }; };

      nixosModules.default = import ./nix/nixos.nix self;
      homeManagerModules.default = import ./nix/home-manager.nix self;

      # `nix develop`, then `qs -p .` to run straight from the checkout
      devShells = forAll (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.quickshell
            pkgs.qt6.qtdeclarative   # qmllint / qmlformat
            pkgs.brightnessctl pkgs.networkmanager pkgs.cliphist pkgs.wl-clipboard pkgs.matugen
          ];
        };
      });
    };
}
