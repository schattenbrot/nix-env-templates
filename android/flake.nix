{
  description = "A flake with Android Studio and Android tools";

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
          androidSdk = (pkgs.androidenv.composeAndroidPackages {
            platformVersions = [ "35" ];
            abiVersions = [ "armeabi-v7a" "arm64-v8a" ];
          }).androidsdk;
        in {
				default = pkgs.mkShell {
					packages = with pkgs; [ 
            android-studio
            android-tools
						gradle
						jdk17
            androidSdk
          ];
          shellHook = ''
            export ANDROID_HOME=${androidSdk}/libexec/android-sdk
            export PATH=$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH
          '';
				};
			});
		};
}
