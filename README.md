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

Bump `version` in `package.nix`, set the three hashes to `lib.fakeHash`, and
`nix build` three times, copying each `got:` hash in.

CI builds and launch-tests the package on x86_64 and aarch64 Linux (the Nix store
is cached in GitHub Actions, keyed on flake.lock + package.nix), and evaluates
the Home Manager module.
