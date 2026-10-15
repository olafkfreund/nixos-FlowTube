# nixos-FlowTube

Nix flake packaging [Flow Desktop](https://github.com/Flow-Tube/Flow-Desktop), a
privacy-respecting YouTube and YouTube Music client (Tauri 2), built from source,
with a Home Manager module.

## Run it

```bash
nix run github:olafkfreund/nixos-FlowTube
```

## Home Manager

```nix
{
  inputs.flowtube = {
    url = "github:olafkfreund/nixos-FlowTube";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # in your home-manager modules:
  imports = [ inputs.flowtube.homeManagerModules.default ];
  programs.flow-desktop.enable = true;
}
```

The module installs the app and registers it as the `flow://` link handler.
`programs.flow-desktop.package` overrides the package.

## NixOS / overlay

```nix
nixpkgs.overlays = [ inputs.flowtube.overlays.default ];
environment.systemPackages = [ pkgs.flow-desktop ];
```

## Packaging notes

- The in-app updater is disabled; update by bumping the flake.
- Video decodes through GStreamer (base, good, bad, ugly, libav are wired in).
- The BotGuard sidecar runs on Node 22; the wrapper sets `FLOW_NODE` and
  `FLOW_INTEGRITY_SCRIPT`, both overridable from the environment.
- Linux GPU workarounds are upstream's own: on NVIDIA + Wayland a blank first
  launch self-heals on the next one. `WEBKIT_DISABLE_DMABUF_RENDERER=1` forces it.

## Updating

The daily `Update` workflow compares `package.nix` with upstream's newest release
(prereleases included, since upstream ships only betas so far). When they differ it
runs `nix-update`, builds and smoke-tests the result, and opens a PR. Run it by hand
from the Actions tab, or locally:

```bash
nix run nixpkgs#nix-update -- --flake flow-desktop --version <new-version>
```

CI builds and launch-tests the package on x86_64 and aarch64 Linux (the Nix store
is cached in GitHub Actions, keyed on flake.lock + package.nix), and evaluates
the Home Manager module.
