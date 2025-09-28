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
			devShells = forEachSupportedSystem ({ pkgs }: {
				default = pkgs.mkShell {
					packages = with pkgs; [ 
            android-studio
            android-tools
						gradle
						jdk17
          ];
          shellHook = ''
            # Set up writable Android SDK directory
            export ANDROID_HOME="$HOME/.android-sdk"
            export ANDROID_SDK_ROOT="$ANDROID_HOME"
            mkdir -p "$ANDROID_HOME"
            
            # Ensure we're not using any Nix store SDK paths
            unset ANDROID_SDK_HOME
            
            # Install Android SDK components if not present
            if [ ! -d "$ANDROID_HOME/cmdline-tools" ]; then
              echo "Installing Android command-line tools..."
              CMDTOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
              TEMP_DIR=$(mktemp -d)
              
              ${pkgs.curl}/bin/curl -L -o "$TEMP_DIR/cmdtools.zip" "$CMDTOOLS_URL"
              ${pkgs.unzip}/bin/unzip -q "$TEMP_DIR/cmdtools.zip" -d "$TEMP_DIR"
              
              mkdir -p "$ANDROID_HOME/cmdline-tools"
              mv "$TEMP_DIR/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
              rm -rf "$TEMP_DIR"
              
              chmod -R u+w "$ANDROID_HOME"
            fi
            
            # Add SDK tools to PATH
            export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
            
            # Install essential SDK components if not present
            if [ ! -d "$ANDROID_HOME/platforms/android-35" ]; then
              echo "Installing Android SDK components..."
              yes | sdkmanager --sdk_root="$ANDROID_HOME" \
                "platform-tools" \
                "platforms;android-35" \
                "build-tools;35.0.0" \
                "ndk;27.1.12297006" || true
            fi
            
            # Create local.properties to override SDK location for Gradle
            if [ -f "android/local.properties" ] || [ -f "local.properties" ]; then
              echo "Updating local.properties with writable SDK path..."
              if [ -f "android/local.properties" ]; then
                echo "sdk.dir=$ANDROID_HOME" > android/local.properties
              fi
              if [ -f "local.properties" ]; then
                echo "sdk.dir=$ANDROID_HOME" > local.properties
              fi
            fi
            
            echo "Android SDK installed to: $ANDROID_HOME"
            echo "Available tools: adb, sdkmanager, avdmanager"
          '';
				};
			});
		};
}
