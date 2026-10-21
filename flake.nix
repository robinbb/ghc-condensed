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

      mkShell = system: extra:
        ghc-nix.legacy ({ inherit system; } // common // extra);
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
