{
  description = "A flake with sqlc and its development tools";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = { self, nixpkgs }:
  let
    supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
      pkgs = import nixpkgs { inherit system; };
    });
  in
  {
    devShells = forEachSupportedSystem ({ pkgs }: {
      default = pkgs.mkShell {
        packages = [
          pkgs.sqlc
        ];
      };
    });
  };
}
