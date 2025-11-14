{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pname = "green";
        version = "0.1.0";

        lib = pkgs.lib;
        popplerDev = pkgs.poppler.dev;
        glibDev = pkgs.glib.dev;
        cairoDev = pkgs.cairo.dev;
        pkgConfigPath = lib.makeSearchPath "pkgconfig" [
          "${popplerDev}/lib/pkgconfig"
          "${glibDev}/lib/pkgconfig"
          "${cairoDev}/lib/pkgconfig"
        ];
        nixCFlagsCompile = "-I${popplerDev}/include/poppler";
      in
      {
        # 開発用シェル: 必要なヘッダ・ツールが揃う
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            pkg-config
            poppler
            poppler.dev
            glib
            glib.dev
            cairo
            cairo.dev
            SDL
          ];

          # pkg-config 経由で必要な .pc ファイルにアクセスできるようにする
          PKG_CONFIG_PATH = pkgConfigPath;
          NIX_CFLAGS_COMPILE = nixCFlagsCompile;
        };

        # ビルド済みバイナリパッケージ
        packages.default = pkgs.stdenv.mkDerivation {
          inherit pname version;

          src = ./.;

          nativeBuildInputs = with pkgs; [
            pkg-config
            SDL
          ];

          buildInputs = with pkgs; [
            poppler
            poppler.dev
            glib
            glib.dev
            cairo
            cairo.dev
            SDL
          ];

          NIX_CFLAGS_COMPILE = nixCFlagsCompile;
          PKG_CONFIG_PATH = pkgConfigPath;

          # Makefile そのまま利用
          buildPhase = ''
            make
          '';

          installPhase = ''
            mkdir -p $out/bin
            mkdir -p $out/share/man/man1
            install -m755 green $out/bin/green
            install -m644 green.1 $out/share/man/man1/green.1
          '';
        };
      }
    );
}