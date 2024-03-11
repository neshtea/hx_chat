{
  description =
    "A flake for running and building the htmx chat-app example for BOB Konferenz 2024.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    ocaml-overlay = {
      url = "github:nix-ocaml/nix-overlays";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        inherit (inputs.gitignore.lib) gitignoreSource;
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ inputs.ocaml-overlay.overlays.default ];
        };
        oPkgs = pkgs.ocamlPackages;
        neshtea = {
          name = "Marco Schneider";
          email = "marco.schneider@posteo.de";
          github = "neshtea";
          githubId = 1588748;
        };
      in {
        packages = {
          default = self.packages.${system}.hxChat;
          hxChat = pkgs.ocamlPackages.buildDunePackage {
            pname = "hx_chat";
            version = "0.1.0";
            minimalOCamlVersion = "4.14";

            src = gitignoreSource ./.;

            buildInputs = [
              oPkgs.dream
              oPkgs.dream-html
              oPkgs.cmdliner
              oPkgs.ptime
              oPkgs.uuidm
              oPkgs.yojson
              oPkgs.caqti
              oPkgs.caqti-lwt
              oPkgs.caqti-driver-sqlite3
            ];

            meta = {
              homepage = "https://github.com/neshtea/hx_chat";
              mainProgram = "hx";
              description =
                "Small example of ocaml with htmx, implementing a chat room.";
              license = pkgs.lib.licenses.mit;
            };
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.dune_3
            pkgs.sqlite
            oPkgs.ocaml
            oPkgs.merlin
            oPkgs.ocaml-lsp
            oPkgs.ocamlformat
          ];
          inputsFrom = [ self.packages.${system}.hxChat ];
        };

      });
}
