{
  description = "A flake for getting started with Scala.";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    { self
    , nixpkgs
    , flake-utils
    ,
    }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
        "x86_64-darwin"
      ];
    in
    flake-utils.lib.eachSystem supportedSystems (
      system:
      let
        buildOverlays =
          { nixpkgs, system, ... }:
          let
            pkgs = import nixpkgs { inherit system; };
            makeOverlays =
              let
                armOverlay =
                  _: prev:
                  let
                    pkgsForx86 = import nixpkgs { localSystem = "x86_64-darwin"; };
                  in
                  prev.lib.optionalAttrs (prev.stdenv.isDarwin && prev.stdenv.isAarch64) {
                    inherit (pkgsForx86) bloop;
                  };
                ammoniteOverlay = final: prev: { ammonite = prev.ammonite.override { jre = pkgs.graalvm-ce; }; };
                bloopOverlay = final: prev: { bloop = prev.bloop.override { jre = final.graalvm-ce; }; };
                scalaCliOverlay = final: prev: { scala-cli = prev.scala-cli.override { jre = final.graalvm-ce; }; };
                javaOverlay = final: _: {
                  jdk = pkgs.graalvm-ce;
                  jre = pkgs.graalvm-ce;
                };
              in
              [
                javaOverlay
                armOverlay
                bloopOverlay
                scalaCliOverlay
                ammoniteOverlay
              ];

            makePackages =
              let
                overlays = makeOverlays;
              in
              import nixpkgs { inherit system overlays; };
            default = makePackages;
          in
          {
            inherit default;
          };

        pkgs = buildOverlays { inherit nixpkgs system; };
        java = pkgs.default.graalvm-ce;
      in
      {
        devShells.default = pkgs.default.mkShell {
          buildInputs = with pkgs.default; [
            ammonite
            bloop
            coursier
            graalvm-ce
            sbt
            scala-cli
            scalafmt
          ];
          shellHook = ''
            #SHOVE THIS JDK SOMEWHERE TO MAKE IDEA HAPPY
            mkdir -p ./.share
            if [ -L "./.share/java" ]; then
              unlink "./.share/java"
            fi
            ln -sf ${java} ./.share/java
          '';
        };
        formatter = pkgs.default.nixpkgs-fmt;
      }
    );
}
