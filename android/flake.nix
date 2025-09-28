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
            ndkVersions = [ "27.1.12297006" ];
            includeNDK = true;
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
            # Create a writable Android SDK directory
            export ANDROID_HOME="$HOME/.android-sdk"
            export ANDROID_SDK_ROOT="$ANDROID_HOME"
            mkdir -p "$ANDROID_HOME"
            
            # Copy SDK contents if not already present
            if [ ! -d "$ANDROID_HOME/platform-tools" ]; then
              echo "Setting up Android SDK..."
              cp -r ${androidSdk}/libexec/android-sdk/* "$ANDROID_HOME/"
              chmod -R u+w "$ANDROID_HOME"
            fi
            
            # Ensure Android tools use our writable SDK
            export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH"
            
            # Remove any references to the read-only Nix store SDK
            unset ANDROID_SDK_HOME
            
            # Create local.properties to override SDK location for Gradle
            echo "Creating local.properties with SDK path..."
            echo "sdk.dir=$ANDROID_HOME" > local.properties 2>/dev/null || true
          '';
				};
			});
		};
}
