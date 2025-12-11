{
  description = "Android tooling needed to run `expo run android`";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }:
        let
          androidPackages = pkgs.androidenv.composeAndroidPackages {
            platformVersions = [ "34" ];
            buildToolsVersions = [ "34.0.0" ];
            includeEmulator = true;
            includeSources = false;
            includeSystemImages = true;
            includeNDK = false;
            abiVersions = [ "x86_64" "arm64-v8a" ];
          };

          androidSdk = androidPackages.androidsdk;
          java = pkgs.openjdk17;
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              androidSdk
              java
              gradle
            ];

            ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
            ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
            JAVA_HOME = "${java}/lib/openjdk";

            shellHook = ''
              export PATH=$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH
            '';
          };
        });
    };
}
