{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/21.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      supportedSystems = {
        "${flake-utils.lib.system.aarch64-darwin}" = "darwin-arm64";
        "${flake-utils.lib.system.x86_64-darwin}" = "darwin-amd64";
      };
    in
      flake-utils.lib.eachSystem (builtins.attrNames supportedSystems) (
        system: let
          pkgs = import nixpkgs {
            inherit system;
          };

          error = message: builtins.throw ("[nix-keysmith] " + message);

          keysmithRelease = options:
            let
              systemName =
                if builtins.hasAttr options.system supportedSystems
                then supportedSystems.${options.system}
                else error ("unsupported system: " + options.system);

              tarSha256 =
                if builtins.hasAttr options.system options.tarSha256
                then options.tarSha256.${options.system}
                else error ("tarSha256 not provided for system: " + options.system);

              url = "https://github.com/dfinity/keysmith/releases/download/${options.release}";

              tar = "keysmith-${systemName}.tar.gz";

              key = pkgs.fetchurl {
                url = "https://sovereign.io/public.key";
                sha256 = options.keySha256;
              };

              sig = pkgs.fetchurl {
                url = "${url}/SHA256.SIG";
                sha256 = options.sigSha256;
              };

              sum = pkgs.fetchurl {
                url = "${url}/SHA256.SUM";
                sha256 = options.sumSha256;
              };
            in
              pkgs.stdenv.mkDerivation {
                name = "keysmith-${options.release}-${systemName}";
                src = pkgs.fetchzip {
                  sha256 = tarSha256;
                  url = "${url}/${tar}";
                };
                nativeBuildInputs = [
                  pkgs.openssl
                ];
                installPhase = ''
                  mkdir -p $out/bin
                  cp $src/keysmith $out/bin/keysmith
                '';
                doInstallCheck = true;
                installCheckPhase = ''
                  openssl dgst -sha256 -verify ${key} -signature ${sig} ${sum}
                '';
              };
        in
          rec {
            # `nix build '.#keysmith'`
            packages.keysmith = keysmithRelease {
              inherit system;
              release = "v1.6.2";

              keySha256 = "sha256-DXNFhaDDU3R7AqzBtVuRQGZJYM72LQNA+mZt4zrC6vU=";
              sigSha256 = "sha256-AFNOPvDsInCqmXFCp2q/yz5xdiEuZQW+TtrxxyFgFL8";
              sumSha256 = "sha256-4atZkXcL92OgdK4NvGw3UL+FaXDbvDvygCWolyE3GvU=";

              tarSha256 = {
                "${flake-utils.lib.system.aarch64-darwin}" = "sha256-+3zowLogWUuw8voeJ/PLIgEVeWthnw5VRmYH5puFOGU=";
                "${flake-utils.lib.system.x86_64-darwin}" = "sha256-/Cdgtrn2w3Y/v2Kekk4gJV7io+ghWkD+xv3JTE6vkOw=";
              };
            };

            # `nix build`
            defaultPackage = packages.keysmith;

            apps.keysmith = flake-utils.lib.mkApp {
              name = "keysmith";
              drv = packages.keysmith;
            };

            # `nix run`
            defaultApp = apps.keysmith;

            # `nix develop`
            devShell = pkgs.mkShell {
              buildInputs = [
                packages.keysmith
              ];
            };
          }
      );
}
