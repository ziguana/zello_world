{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-pending.url = "github:ziguana/nixpkgs/level_zero";
  };
  outputs =
    inputs:
    let
      overlay-pending = final: prev: {
        pending = import inputs.nixpkgs-pending {
          system = "x86_64-linux";
        };
      };
      pkgs = import inputs.nixpkgs { system = "x86_64-linux"; overlays = [ overlay-pending ]; };
    in
    with pkgs; rec {
      packages.x86_64-linux.default =
        let
          # on a running system, `libze_intel_gpu.so` will be in `/run/opengl-driver`
          # which is in RUNPATH of the loader. here, we must put it into LD_LIBRARY_PATH
          libPath = lib.makeLibraryPath [ pending.intel-compute-runtime.drivers ];
        in
        stdenv.mkDerivation {
          src = ./.;
          name = "zello_world";

          nativeBuildInputs = [
            pkg-config
            cmake
            makeWrapper
          ];
          buildInputs = [ pending.level-zero ];

          postInstall = ''
            wrapProgram $out/bin/zello_world --set LD_LIBRARY_PATH ${libPath}
          '';
        };
      packages.x86_64-linux.tests =
        let
          libPath = lib.makeLibraryPath [ pending.intel-compute-runtime.drivers ];
        in
        stdenv.mkDerivation {
          name = "level-zero-tests";
          version = "1.8.8";
          src = fetchFromGitHub {
            owner = "oneapi-src";
            repo = "level-zero-tests";
            rev = "773b6605ff2d6d0b4350e4a03d5f19e70b0239ec";
            sha256 = "sha256-3Rdhzmg+/4Gwkk2aiCm0iaeRRT8U7074lu/J18QRw4I=";
            fetchSubmodules = true;
          };
          patches = [ ./tests_include_thread.patch ];

          nativeBuildInputs = [ cmake (boost.override { enableShared = false; }) libpng icu ];
          buildInputs = [ pending.level-zero ];

          meta = with lib; {
            homepage = "https://www.oneapi.io/";
            description = "oneAPI Level Zero Conformance & Performance Tests";
            license = licenses.mit;
            maintainers = [ maintainers.ziguana ];
          };
        };
      devShells.x86_64-linux.default =
        let
          libPath = lib.makeLibraryPath [ (enableDebugging pending.intel-compute-runtime).drivers ];
          level-zero = (enableDebugging pending.level-zero);
        in
        pkgs.mkShell {
          inputsFrom = builtins.attrValues packages.x86_64-linux;

          buildInputs = [
            gdb
            bear
            level-zero
          ];

          LD_LIBRARY_PATH = "${libPath}";
        };
    };
}
