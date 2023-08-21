{
  inputs =
    {
      nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      npmlock2nix.url = "github:nix-community/npmlock2nix";
      npmlock2nix.flake = false;
      ps-tools.follows = "purs-nix/ps-tools";
      purs-nix.url = "github:purs-nix/purs-nix/ps-0.15";
      utils.url = "github:ursi/flake-utils";
    };

  outputs = { self, utils, ... }@inputs:
    utils.apply-systems
      {
        inherit inputs;
        # Limited by ps-tools
        systems = [ "x86_64-linux" "x86_64-darwin" ];
        make-pkgs = system: import inputs.nixpkgs {
          inherit system;
          # required by npmlock2nix
          config.permittedInsecurePackages = [
            "nodejs-16.20.2"
          ];
        };
      }
      ({ pkgs, system, ... }:
        let
          inherit (pkgs) nodejs;
          npm = import inputs.npmlock2nix { inherit pkgs; };
          node_modules = npm.v2.node_modules { src = ./.; inherit nodejs; } + /node_modules;
          ps-tools = inputs.ps-tools.legacyPackages.${system};
          inherit (ps-tools.for-0_15) purescript purs-tidy purescript-language-server;
          purs-nix = inputs.purs-nix { inherit system; };
          affjax-node_ = pkgs.lib.recursiveUpdate purs-nix.ps-pkgs.affjax-node {
            purs-nix-info.foreign."Affjax.Node" = { inherit node_modules; };
          };
          ps =
            purs-nix.purs
              {
                dir = ./.;
                dependencies =
                  with purs-nix.ps-pkgs;
                  [
                    prelude
                    debug
                    aff
                    affjax-node_
                    argonaut-codecs
                    argonaut-generic
                    effect
                    httpure
                    node-buffer
                    node-process
                    node-streams-aff
                    test-unit
                    parsing
                  ];
                inherit purescript nodejs;
              };
        in
        with ps;
        rec {
          apps.default =
            {
              type = "app";
              program = "${self.packages.${system}.default}";
            };

          packages =
            with ps;
            {
              default = pkgs.writeScript "purs-eval" ''
                #!${pkgs.nodejs}/bin/node
                import("${self.packages.${system}.output}/Main/index.js").then(m=>m.main())
              '';
              output = output { };
            };

          checks.test = test.check { };

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              nodejs
              (ps.command { })
              purescript-language-server
              purs-tidy
              purescript
              purs-nix.esbuild
            ];
          };
        }
      );

  nixConfig = {
    extra-experimental-features = "nix-command flakes";
    extra-substituters = [
      "https://klarkc.cachix.org"
    ];
    extra-trusted-public-keys = [
      "klarkc.cachix.org-1:R+z+m4Cq0hMgfZ7AQ42WRpGuHJumLLx3k0XhwpNFq9U="
    ];
  };
}
