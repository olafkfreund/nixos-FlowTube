# Evaluates a Home Manager config that enables the module; run with
#   nix eval --impure --raw --file tests/hm.nix
let
  self = builtins.getFlake (toString ../.);
  hm = builtins.getFlake "github:nix-community/home-manager";
  pkgs = self.inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
  home = hm.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      self.homeManagerModules.default
      {
        home.username = "ci";
        home.homeDirectory = "/home/ci";
        home.stateVersion = "25.05";
        programs.flow-desktop.enable = true;
      }
    ];
  };
in
assert builtins.elem self.packages.${builtins.currentSystem}.default home.config.home.packages;
assert home.config.xdg.mimeApps.defaultApplications."x-scheme-handler/flow" == [ "Flow.desktop" ];
home.activationPackage.drvPath
