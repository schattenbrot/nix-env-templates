{
  description = "A flake with Node.js 20";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
        forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
          pkgs = import nixpkgs { inherit system; overlays = [ self.overlays.default ]; };
        });
    in
      {
        overlays.default = final: prev: rec {
          nodejs = prev.nodejs;
        };

        devShells = forEachSupportedSystem ({ pkgs }: {
          default = pkgs.mkShell {
            packages = with pkgs; [
              go
              gotools
            ];
          };
        });
      };
}
