{
  description = "Dev shells for Go, Python, and Rust";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    ,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        nu = pkgs.nushell;

        pythonEnv = pkgs.python3.withPackages (
          ps: with ps; [
            pip
            virtualenv
          ]
        );

        nuHook = ''
          export SHELL=${nu}/bin/nu
          exec nu
        '';

        mkNuShell =
          args:
          pkgs.mkShell (
            args
            // {
              buildInputs = (args.buildInputs or [ ]) ++ [ nu ];
              shellHook = (args.shellHook or "") + nuHook;
            }
          );
      in
      {
        devShells.rust = mkNuShell {
          name = "rust-dev";
          buildInputs = with pkgs; [
            cargo
            rustc
            rustfmt
            clippy
            rust-analyzer
            pkg-config
            openssl
          ];
          RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
          PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
          RUST_LOG = "debug";
          shellHook = ''
            export IN_NIX_SHELL="rust"
            echo "$(rustc --version)"
          '';
        };

        devShells.python = pkgs.mkShell {
          name = "python-dev";
          buildInputs = [
            pythonEnv
            nu
          ];
          shellHook = ''
            if [ ! -d .venv ]; then
              python -m venv .venv
            fi
            if [ -f requirements.txt ]; then
              pip install -r requirements.txt
            fi
            echo "$(python --version)"
            export VIRTUAL_ENV="$PWD/.venv"
            export PATH="$PWD/.venv/bin:$PATH"
            export SHELL=${nu}/bin/nu
            exec nu
          '';
        };

        devShells.go = mkNuShell {
          name = "go-dev";
          buildInputs = with pkgs; [
            go
            gopls
            gotools
            delve
          ];
          shellHook = ''
            export IN_NIX_SHELL="go"
            echo "$(go version)"
          '';
        };
      }
    );
}
