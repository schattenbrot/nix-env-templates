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
			devShells = forEachSupportedSystem ({ pkgs }: let
        # Create an FHS environment for Android tools compatibility
        androidFHS = pkgs.buildFHSEnv {
          name = "android-sdk-env";
          targetPkgs = pkgs: with pkgs; [
            glibc
            zlib
            ncurses5
            stdenv.cc.cc.lib
            libGL
            libpulseaudio
            fontconfig
            freetype
            xorg.libX11
            xorg.libXext
            xorg.libXi
            xorg.libXrender
            xorg.libXtst
          ];
          multiPkgs = pkgs: with pkgs; [
            zlib
          ];
        };
      in {
				default = pkgs.mkShell {
					packages = with pkgs; [ 
            android-studio
            android-tools
						gradle
						jdk17
            cmake
            ninja
            python3
            # Additional tools for React Native builds
            pkg-config
            nodejs
            yarn
            # Libraries needed for Android SDK tools on NixOS
            stdenv.cc.cc.lib
            zlib
            ncurses5
            # FHS environment for Android tools
            androidFHS
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
                "ndk;27.1.12297006" \
                "cmake;3.22.1" || true
            fi
            
            # Force reinstall build-tools if corrupted
            if [ -f "$ANDROID_HOME/build-tools/35.0.0/aapt2.original" ] || [ ! -f "$ANDROID_HOME/build-tools/35.0.0/aapt2" ]; then
              echo "Reinstalling Android build-tools..."
              rm -rf "$ANDROID_HOME/build-tools/35.0.0" 2>/dev/null || true
              yes | sdkmanager --sdk_root="$ANDROID_HOME" "build-tools;35.0.0" || true
            fi
            
            # Replace Android SDK's CMake with NixOS-compatible version
            if [ -d "$ANDROID_HOME/cmake/3.22.1/bin" ]; then
              # Ensure the directory is writable
              chmod -R u+w "$ANDROID_HOME/cmake/3.22.1" 2>/dev/null || true
              
              # Create backup of original binaries
              if [ ! -f "$ANDROID_HOME/cmake/3.22.1/bin/cmake.original" ]; then
                cp "$ANDROID_HOME/cmake/3.22.1/bin/cmake" "$ANDROID_HOME/cmake/3.22.1/bin/cmake.original" 2>/dev/null || true
                cp "$ANDROID_HOME/cmake/3.22.1/bin/ninja" "$ANDROID_HOME/cmake/3.22.1/bin/ninja.original" 2>/dev/null || true
              fi
              
              # Create simple symlinks to NixOS-compatible versions
              ln -sf ${pkgs.cmake}/bin/cmake "$ANDROID_HOME/cmake/3.22.1/bin/cmake" 2>/dev/null || true
              ln -sf ${pkgs.ninja}/bin/ninja "$ANDROID_HOME/cmake/3.22.1/bin/ninja" 2>/dev/null || true
            fi
            
            # Restore build-tools if they were corrupted by previous symlinks
            if [ -f "$ANDROID_HOME/build-tools/35.0.0/aapt2.original" ]; then
              echo "Restoring original build-tools..."
              mv "$ANDROID_HOME/build-tools/35.0.0/aapt2.original" "$ANDROID_HOME/build-tools/35.0.0/aapt2" 2>/dev/null || true
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
            
            # Set environment variables for React Native builds
            export ANDROID_NDK="$ANDROID_HOME/ndk/27.1.12297006"
            export ANDROID_NDK_ROOT="$ANDROID_NDK"
            
            # Add CMake to PATH for React Native builds 
            export PATH="${pkgs.cmake}/bin:$PATH"
            
            # Set up dynamic linker for Android SDK tools on NixOS
            export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib:${pkgs.ncurses5}/lib:$LD_LIBRARY_PATH"
            
            # Ensure build tools have proper permissions and are not corrupted
            if [ -d "$ANDROID_HOME/build-tools/35.0.0" ]; then
              chmod +x "$ANDROID_HOME/build-tools/35.0.0"/* 2>/dev/null || true
            fi
            
            echo "Android SDK installed to: $ANDROID_HOME"
            echo "Android NDK: $ANDROID_NDK"
            echo "Using CMake: $(which cmake)"
            echo "Available tools: adb, sdkmanager, avdmanager, aapt2"
          '';
				};
			});
		};
}
