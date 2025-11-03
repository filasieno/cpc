{
  description = "CPC - A CIL-based C program analysis framework";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    ocamlPackages = pkgs.ocaml-ng.ocamlPackages_4_14;
  in {

    packages.x86_64-linux.cpc = pkgs.stdenv.mkDerivation {
      pname = "cpc";
      version = "0.9.1";

      src = ./.;

      nativeBuildInputs = [
        pkgs.autoconf
        pkgs.automake
        pkgs.pkg-config
        pkgs.perl
        ocamlPackages.ocaml
        ocamlPackages.findlib
        ocamlPackages.ocamlbuild
        ocamlPackages.num
      ];

      buildInputs = [
        pkgs.gcc
      ];

      configurePhase = ''
        ./configure
      '';

      buildPhase = ''
        # Build the libraries and object files, but not the final executables
        ocamlbuild -build-dir _build -no-links -classic-display -use-ocamlfind \
          src/cil.cma src/cil.cmxa src/cil.a src/cil.libfiles \
          src/cilly.cmo src/cilly.cmx \
          cil.docdir/index.html

        # Manually link executables to avoid duplicate module linking issue
        echo "Manually linking executables..."

        # Link bytecode version
        ocamlfind ocamlc -linkpkg -package unix -package str -package num \
          -I _build/src _build/src/cil.cma _build/src/cilly.cmo \
          -o src/cilly.byte

        # Link native version
        ocamlfind ocamlopt -linkpkg -package unix -package str -package num \
          -I _build/src _build/src/cil.cmxa _build/src/cilly.cmx \
          -o src/cilly.native
      '';

      installPhase = ''
        mkdir -p $out/bin

        # Install the native executable
        cp src/cilly.native $out/bin/cpc

        # Install the bytecode executable as well
        cp src/cilly.byte $out/bin/cpc.byte

        # Copy the Perl wrapper
        cp bin/cpc $out/bin/cpc.pl
      '';

      meta = with pkgs.lib; {
        description = "CPC - A CIL-based C program analysis framework";
        homepage = "http://www.pps.univ-paris-diderot.fr/~kerneis/software/cpc";
        license = licenses.lgpl21;
        maintainers = [ ];
        platforms = platforms.linux;
      };
    };

    packages.x86_64-linux.default = self.packages.x86_64-linux.cpc;

    devShells.x86_64-linux.default = pkgs.mkShell {
      buildInputs = [
        pkgs.gcc
        ocamlPackages.ocaml
        ocamlPackages.dune_2
        ocamlPackages.findlib
        ocamlPackages.merlin
        ocamlPackages.utop
        ocamlPackages.ocamlformat
        ocamlPackages.menhir
        ocamlPackages.odoc
        ocamlPackages.ocamlbuild
        ocamlPackages.num
      ];
      nativeBuildInputs = [
        pkgs.autoconf
        pkgs.automake
        pkgs.pkg-config
        pkgs.perl
      ];
      shellHook = ''
        export PS1="(cpc) \033[32m\033[1m[\033[33m\033[1m\w\033[0m\033[32m]\033[0m$ "
        export PERL5LIB="$PWD/test:$PERL5LIB"
      '';
    };

  };
}
