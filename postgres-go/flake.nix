{
  description = "Postgres flake for Go and it's development tools";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in
  {
    devShells.${system}.default = pkgs.mkShell {
      packages = [
        pkgs.dbeaver-bin
        (pkgs.go-migrate.overrideAttrs (old: {
          tags = ["postgres"];
        }))
      ];
    };
  };
}
