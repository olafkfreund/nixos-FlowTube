{
  lib,
  stdenv,
  fetchFromGitHub,
  cargo-tauri,
  jq,
  moreutils,
  nodejs_22,
  nodejs-slim_22,
  openssl,
  pkg-config,
  pnpm_11,
  fetchPnpmDeps,
  pnpmConfigHook,
  rustPlatform,
  glib-networking,
  libsoup_3,
  webkitgtk_4_1,
  gst_all_1,
  wrapGAppsHook3,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "flow-desktop";
  version = "0.1.0-beta2";

  src = fetchFromGitHub {
    owner = "Flow-Tube";
    repo = "Flow-Desktop";
    tag = "v${finalAttrs.version}";
    hash = "sha256-thvMpWw3oomGHL97fywhgCRiCqrMFBFtErvTIgBYX4M=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) src pname version;
    pnpm = pnpm_11;
    fetcherVersion = 4;
    hash = "sha256-DXKpvlEyHJzer93vu3o7cNuQfVw17W1L7RhPiXmvHGg=";
  };

  cargoRoot = "src-tauri";
  buildAndTestSubdir = finalAttrs.cargoRoot;

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs)
      pname
      version
      src
      cargoRoot
      ;
    hash = "sha256-l07uP65p7EAQ/ztSKBK9ffncY6uG9F/TY0nK4k5rU3s=";
  };

  # The in-app updater would try to replace a read-only store path. Runtime flow://
  # registration would write a desktop entry pointing at the store path of the
  # unwrapped binary; the packaged Flow.desktop already declares the scheme.
  postPatch = ''
    substituteInPlace src-tauri/src/lib.rs \
      --replace-fail '#[cfg(any(target_os = "linux", all(debug_assertions, windows)))]' \
                     '#[cfg(all(debug_assertions, windows))]'
    jq '.plugins.updater.endpoints = [ ] | .bundle.createUpdaterArtifacts = false' \
      src-tauri/tauri.conf.json | sponge src-tauri/tauri.conf.json
  '';

  nativeBuildInputs = [
    cargo-tauri.hook
    jq
    moreutils
    nodejs_22
    pkg-config
    pnpmConfigHook
    pnpm_11
    rustPlatform.cargoSetupHook
    wrapGAppsHook3
  ];

  buildInputs = [
    glib-networking
    libsoup_3
    openssl
    webkitgtk_4_1
  ]
  # WebKitGTK decodes video through the system GStreamer plugins.
  ++ (with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-plugins-ugly
    gst-libav
  ]);

  env.OPENSSL_NO_VENDOR = "1";

  # Upstream's Rust tests open sockets and write app data; the release build is the check.
  doCheck = false;

  # The binary only searches for its BotGuard sidecar next to itself, not in lib/Flow.
  preFixup = ''
    gappsWrapperArgs+=(
      --set-default FLOW_NODE ${lib.getExe nodejs-slim_22}
      --set-default FLOW_INTEGRITY_SCRIPT $out/lib/Flow/sidecar/integrity.cjs
      --prefix PATH : ${lib.makeBinPath [ gst_all_1.gstreamer ]}
    )
  '';

  meta = {
    description = "Privacy-respecting YouTube and YouTube Music desktop client";
    homepage = "https://github.com/Flow-Tube/Flow-Desktop";
    license = lib.licenses.gpl3Only;
    mainProgram = "flow";
    platforms = lib.platforms.linux;
  };
})
