self:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.flow-desktop;
in
{
  options.programs.flow-desktop = {
    enable = lib.mkEnableOption "Flow Desktop, a privacy-respecting YouTube client";
    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = lib.literalExpression "flow-desktop from the nixos-FlowTube flake";
      description = "The Flow Desktop package to install.";
    };
  };

  # Flow.desktop declares x-scheme-handler/flow, so flow:// links resolve via the
  # profile's mimeinfo.cache without touching the user's mimeapps.list.
  config = lib.mkIf cfg.enable { home.packages = [ cfg.package ]; };
}
