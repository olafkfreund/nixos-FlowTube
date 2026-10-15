{
  description = "Nix package and Home Manager module for Flow Desktop (Flow-Tube)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        flow-desktop = pkgs.callPackage ./package.nix { };
        default = flow-desktop;
      });

      overlays.default = final: _prev: {
        flow-desktop = final.callPackage ./package.nix { };
      };

      homeManagerModules.default = import ./hm-module.nix self;

      checks = forAllSystems (
        pkgs:
        let
          flow = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
        in
        {
          package = flow;
          # Passes if the app is still running after 20s under Xvfb (timeout exits 124).
          smoke = pkgs.runCommand "flow-desktop-smoke" { nativeBuildInputs = [ pkgs.xvfb-run ]; } ''
            export HOME=$TMPDIR XDG_RUNTIME_DIR=$TMPDIR SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
            rc=0; timeout 20 xvfb-run -a ${flow}/bin/flow > log 2>&1 || rc=$?
            cat log
            test "$rc" -eq 124 && touch $out
          '';
        }
      );

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
