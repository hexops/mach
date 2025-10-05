{ pkgs ? import <nixpkgs> {} }:

let
  zigVersion = builtins.replaceStrings ["\n"] [""] (builtins.readFile ./.zigversion);

  # Determine platform-specific details
  platform = if pkgs.stdenv.isDarwin then "macos" else "linux";
  arch = if pkgs.stdenv.isAarch64 then "aarch64" else "x86_64";

  # URL for the Zig binary
  zigUrl = "https://pkg.machengine.org/zig/zig-${platform}-${arch}-${zigVersion}.tar.xz";

  zigSrc = pkgs.fetchurl {
    url = zigUrl;
    hash = "sha256-/vTDPMiyya8cr0ffmHhsa8BJ3XDsbAXHlKMnOyk3gBs=";
  };

  zigVersionCompatibleWithMach = pkgs.stdenv.mkDerivation {
    pname = "zig";
    version = zigVersion;

    src = zigSrc;

    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
        mkdir -p $out/bin
        cp -r ./* $out/
        chmod +x $out/zig
        ln -s $out/zig $out/bin/zig
    '';
  };

in pkgs.mkShell {
  buildInputs = [
    pkgs.git
    zigVersionCompatibleWithMach
  ];

  shellHook = ''
    echo "Zig ${zigVersion} loaded"
    zig version
  '';
}
