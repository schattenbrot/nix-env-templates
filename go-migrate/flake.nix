{
  description = "A flake with go-migrate for Postgres";

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
          (pkgs.go-migrate.overrideAttrs (old: {
            tags = [
              "cassandra"
              "clickhouse"
              "cockroachdb"
              "crate"
              "firebird"
              "mongodb"
              "multistmt"
              "mysql"
              "neo4j"
              "pgx"
              "pgx5"
              "postgres"
              "ql"
              "redshift"
              "rqlite"
              "shell"
              "spanner"
              "sqlite3"
              "sqlserver"
              "stub"
              "testing"
              "yugabytedb"
            ];
          }))
        ];
      };
    });
  };
}
