{
  description = "Pinky Studios site portfolio deployment";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      name = "pinky";
    in rec {
      devShell = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [ bashInteractive hugo rsync ];
        buildInputs = [ ];
      };
      apps.server = {
        type = "app";
        program = toString (pkgs.writers.writeBash "testing" ''
          ${pkgs.hugo}/bin/hugo server -D
        '');
      };
      apps.rsync = {
        type = "app";
        program = toString (pkgs.writers.writeBash "rsync" ''
          ${pkgs.rsync}/bin rsync -avz --delete public/ sea:/var/www/pinkystudios.com
        '');        
      };
      packages."${name}" = pkgs.stdenv.mkDerivation {
        pname = name;
        version = "1.0";
        src = ./.;
        buildInputs = [ pkgs.hugo pkgs.git ];
        buildPhase = ''
          hugo --minify
        '';
        installPhase = "cp -vr public $out";
      };
      defaultPackage = packages."${name}";
      defaultApp = apps.server;
    });
}
