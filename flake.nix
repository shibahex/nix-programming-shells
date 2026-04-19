{
  description = "Dev shells for Go, Python, and Rust";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          pip
          virtualenv
        ]);

      in
      {

        devShells.rust = pkgs.mkShell {
          name = "rust-dev";
          buildInputs = with pkgs; [
            cargo
            rustc
            rustfmt
            clippy
            rust-analyzer
            pkg-config
            openssl
            nushell
          ];
          RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
          PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
          RUST_LOG = "debug";
          shellHook = ''
            export IN_NIX_SHELL="rust"
            export SHELL=${pkgs.nushell}/bin/nu
            exec nu
          '';
        };

        devShells.python = pkgs.mkShell {
          name = "python-dev";
          buildInputs = [ pythonEnv ];
          shellHook = ''
            exec nu
            if [ ! -d .venv ]; then
              echo "Creating virtual environment..."
              python -m venv .venv
            fi
            source .venv/bin/activate
            if [ -f requirements.txt ]; then
              echo "Installing requirements..."
              pip install -r requirements.txt
            fi
            echo "Python $(python --version)"
          '';
        };

        devShells.go = pkgs.mkShell {
          name = "go-dev";
          buildInputs = with pkgs; [
            go
            gopls
            gotools
            delve
          ];
          shellHook = ''
            export IN_NIX_SHELL="go"
            exec nu
            echo "Go $(go version)"
          '';
        };

      }
    );
}
