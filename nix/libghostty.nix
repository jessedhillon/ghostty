{
  lib,
  stdenv,
  callPackage,
  gobject-introspection,
  blueprint-compiler,
  libxml2,
  gettext,
  wrapGAppsHook4,
  git,
  ncurses,
  pkg-config,
  zig_0_15,
  pandoc,
  wayland-protocols,
  wayland-scanner,
  pkgs,
  revision ? "dirty",
  optimize ? "Debug",
  enableX11 ? true,
  enableWayland ? true,
}:
let
  buildInputs = import ./build-support/build-inputs.nix {
    inherit pkgs lib stdenv enableX11 enableWayland;
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "libghostty";
  version = "0.1.0-dev";

  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.intersection (lib.fileset.fromSource (lib.sources.cleanSource ../.)) (
      lib.fileset.unions [
        ../dist/linux
        ../images
        ../include
        ../po
        ../pkg
        ../src
        ../vendor
        ../build.zig
        ../build.zig.zon
        ../build.zig.zon.nix
      ]
    );
  };

  deps = callPackage ../build.zig.zon.nix {name = "ghostty-cache-${finalAttrs.version}";};

  nativeBuildInputs = [
    git
    ncurses
    pandoc
    pkg-config
    zig_0_15
    gobject-introspection
    wrapGAppsHook4
    blueprint-compiler
    libxml2
    gettext
  ] ++ lib.optionals enableWayland [
    wayland-scanner
    wayland-protocols
  ];

  inherit buildInputs;

  dontSetZigDefaultFlags = true;

  zigBuildFlags = [
    "--system"
    "${finalAttrs.deps}"
    "-fsys=freetype"
    "-fsys=harfbuzz"
    "-fsys=fontconfig"
    "-fsys=libpng"
    "-fsys=zlib"
    "-fsys=oniguruma"
    "-fsys=gtk4-layer-shell"
    "-Dversion-string=${finalAttrs.version}-${revision}-nix"
    "-Dcpu=baseline"
    "-Doptimize=${optimize}"
    "-Dapp-runtime=none"
    "-Demit-lib-vt=false"
    "-Demit-docs=false"
  ];

  outputs = [
    "out"
    "dev"
  ];

  postInstall = ''
    mkdir -p "$dev/lib"
    mv "$out/lib/libghostty.a" "$dev/lib"
    mv "$out/include" "$dev"

    ln -sf "$out/lib/libghostty.so" "$dev/lib/libghostty.so"
  '';

  meta = {
    homepage = "https://ghostty.org";
    license = lib.licenses.mit;
    platforms = zig_0_15.meta.platforms;
  };
})
