{
  description = "Anoma specs";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/master";
  inputs.utils.url = "github:numtide/flake-utils";

  outputs = {
    self,
    nixpkgs,
    utils,
  }:
    utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs rec {
        inherit system;
      };
    in rec {
      packages =  with pkgs; rec {
        anoma-specs = stdenv.mkDerivation rec {
          pname = "anoma-specs";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = [
            mdbook
            mdbook-linkcheck
            mdbook-katex

            pandoc
            pandoc-include

            graphviz
            gyre-fonts
            librsvg
            texlive.combined.scheme-full
           ];

          buildPhase = ''
            make build pdf
          '';
          installPhase = ''
            mkdir -p $out
            cp -a book/html book/*.pdf $out
          '';

          meta = with lib; {
            homepage = "https://specs.anoma.net";
            description = "Anoma specifications";
          };
        };
        default = anoma-specs;
      };
    }
  );
}
