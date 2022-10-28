{
  inputs =
    {
      nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      ps-tools.follows = "purs-nix/ps-tools";
      purs-nix.url = "github:purs-nix/purs-nix/ps-0.15";
      utils.url = "github:ursi/flake-utils";
    };

  outputs = { utils, ... }@inputs:
    utils.apply-systems { inherit inputs; } ({ pkgs, system, ... }:
      let
        ps-tools = inputs.ps-tools.legacyPackages.${system};
        purs-nix = inputs.purs-nix { inherit system; };
        ps =
          purs-nix.purs
            {
              dependencies =
                with purs-nix.ps-pkgs;
                [
                  effect
                  prelude
                  node-process
                ];

              dir = ./.;
            };
      in
      rec {
        apps.default = {
          type = "app";
          program = "${packages.default}/bin/purs-eval";
        };

        packages = with ps.modules.Main; {
          default = app { name = "purs-eval"; };
          bundle = bundle { };
          output = output { };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nodejs
            (ps.command { })
            ps-tools.for-0_15.purescript-language-server
            purs-nix.esbuild
            purs-nix.purescript
          ];
        };
      }
    );
}
