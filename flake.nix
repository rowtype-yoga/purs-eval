{
  inputs =
    {
      purs-nix.url = "github:purs-nix/purs-nix";
      nixpkgs.follows = "purs-nix/nixpkgs";
      utils.url = "github:ursi/flake-utils";
      ps-tools.follows = "purs-nix/ps-tools";
      npmlock2nix = {
        url = "github:nix-community/npmlock2nix";
        flake = false;
      };
      httpurple-argonaut = {
        url = "github:sigma-andex/purescript-httpurple-argonaut"; 
        flake = false;
      };
    };

  outputs = { self, utils, ... }@inputs:
    utils.apply-systems
      {
        inherit inputs;
        # Limited by ps-tools
        systems = [ "x86_64-linux" "x86_64-darwin" ];
      }
      ({ pkgs, system, ... }@ctx:
        let
          inherit (pkgs) nodejs;
          npm = import inputs.npmlock2nix { inherit pkgs; };
          node_modules = npm.v2.node_modules { src = ./.; inherit nodejs; } + /node_modules;
          inherit (ctx.ps-tools) purescript purs-tidy purescript-language-server;
          purs-nix = inputs.purs-nix { inherit system; };
          affjax-node_ = pkgs.lib.recursiveUpdate purs-nix.ps-pkgs.affjax-node {
            purs-nix-info.foreign."Affjax.Node" = { inherit node_modules; };
          };
          # TODO use httpurple-argonaut from official index
          httpurple-argonaut_ = purs-nix.build 
          { 
            name = "httpurple-argonaut";
            src.path = inputs.httpurple-argonaut;
            info.dependencies = [ "argonaut" "console" "effect" "either" "httpurple" "prelude"];
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
                    httpurple
                    httpurple-argonaut_
                    test-unit
                    parsing
                  ];
                inherit purescript nodejs;
              };
          name = "purs-eval";
        in
        with ps;
        rec {
          apps.default =
            {
              type = "app";
              program = "${packages.default}/bin/${name}";
            };

          packages =
            with ps;
            {
              default = app { inherit name; };
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
