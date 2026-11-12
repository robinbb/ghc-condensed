# Development environment for building GHC-Condensed with Nix.
#
# Everything comes from ghc.nix <https://gitlab.haskell.org/ghc/ghc.nix>,
# the GHC project's own Nix setup: a bootstrap GHC, cabal-install, alex,
# happy, autotools, and the C libraries GHC links against (gmp, ncurses,
# libffi, libdw, libnuma, zstd). See README.md, section "Nix", for usage.
#
# ghc.nix pins its own nixpkgs and bootstrap GHC; flake.lock pins ghc.nix.
# Run `nix flake update` to move all of them forward together.
{
  description = "Build environment for GHC-Condensed";

  inputs.ghc-nix.url = "gitlab:ghc/ghc.nix?host=gitlab.haskell.org";

  outputs = { ghc-nix, ... }:
    let
      # Settings shared by every shell. The full list of knobs is in the
      # table in ghc.nix's README (bootghc, withLlvm, withDwarf, ...).
      common = {
        withHadrianDeps = true; # most of Hadrian's deps via Nix
        withDocs = false; # Sphinx + XeLaTeX: see the `docs` shell
        withIde = false; # haskell-language-server: see `ide`
      };

      # System libraries needed by packages in external-packages/ (see
      # external-packages/README.md), taken from ghc.nix's own nixpkgs so
      # that everything in the shell comes from one snapshot.
      externalLibs = system:
        let pkgs = ghc-nix.inputs.nixpkgs.legacyPackages.${system};
        in {
          buildInputs = with pkgs; [ zlib SDL2 openssl fcgi file ];
          # fsatrace: shake's test suite traces commands through it, as its
          # own CI does.
          nativeBuildInputs = with pkgs; [ pkg-config fsatrace ];
        };

      mkShell = system: extra:
        (ghc-nix.legacy ({ inherit system; } // common // extra)).overrideAttrs
          (old: {
            buildInputs = (old.buildInputs or [ ])
              ++ (externalLibs system).buildInputs;
            nativeBuildInputs = (old.nativeBuildInputs or [ ])
              ++ (externalLibs system).nativeBuildInputs;
          });
    in
    {
      devShells = ghc-nix.lib.perSystem (system: {
        # Enough to boot, configure and build the compiler.
        default = mkShell system { };
        # Adds haskell-language-server and clangd.
        ide = mkShell system { withIde = true; };
        # Adds the tools needed to build the user's guide and haddocks.
        docs = mkShell system { withDocs = true; };
      });
    };
}
