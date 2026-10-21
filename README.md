GHC-Condensed
============================

For more information, visit [GHC's web site][1].


Building & Installing
=====================

For full information on building GHC, see the [GHC Building Guide][3].
Here follows a summary - if you get into trouble, the Building Guide
has all the answers.

Before building GHC you may need to install some other tools and
libraries.  See, [Setting up your system for building GHC][8].

*NB.* In particular, you need [GHC][1] installed in order to build GHC,
because the compiler is itself written in Haskell.  You also need
[Happy][4], [Alex][5], and [Cabal][9].  For instructions on how
to port GHC to a new platform, see the [GHC Building Guide][3].

For building library documentation, you'll need [Haddock][6].  To build
the compiler documentation, you need [Sphinx](http://www.sphinx-doc.org/)
and Xelatex (only for PDF output).

**Quick start**: GHC is built using the [Hadrian build system](hadrian/README.md).
The following gives you a default build:

    $ ./boot
    $ ./configure
    $ hadrian/build         # can also say '-jX' for X number of jobs

  On Windows, you need an extra repository containing some build tools.
  These can be downloaded for you by configure. This only needs to be done once by running:

    $ ./configure --enable-tarballs-autodownload

  Additionally, on Windows, to run Hadrian you should run `hadrian/build.bat`
  instead of `hadrian/build`.

(NB: **Do you have multiple cores? Be sure to tell that to `hadrian`!** This can
save you hours of build time depending on your system configuration, and is
almost always a win regardless of how many cores you have. As a simple rule,
you should have about N+1 jobs, where `N` is the amount of cores you have.)

The `./boot` step is only necessary if this is a tree checked out
from git.  For source distributions downloaded from [GHC's web site][1],
this step has already been performed.

These steps give you the default build, which includes everything
optimised and built in various ways (eg. profiling libs are built).
It can take a long time.  To customise the build, see the file `HACKING.md`.

## Nix

This repository ships a `flake.nix` that provides a complete build
environment through [ghc.nix][14], the GHC project's own Nix setup: a
bootstrap GHC, `cabal-install`, `alex`, `happy`, the autotools, and the C
libraries GHC links against. You need Nix with the `nix-command` and
`flakes` experimental features enabled. Then:

    $ git submodule update --init --recursive
    $ nix develop                  # enter the build environment
    $ ./boot && configure_ghc      # runs ./configure $CONFIGURE_ARGS
    $ cabal update                 # Hadrian pins a recent index-state
    $ hadrian/build -j             # as above; results land in _build/

`configure_ghc` passes the `--with-gmp-*`, `--with-curses-*`, and similar
flags that point `configure` at the Nix store paths of GHC's C
dependencies. To add flags of your own, append them to `configure_ghc`,
or call `./configure $CONFIGURE_ARGS ...` directly (in zsh, write
`${=CONFIGURE_ARGS}`).

The compiler you built is `_build/stage1/bin/ghc`. Run it from inside the
shell, which supplies the C toolchain it needs for linking.

The default shell is deliberately lean. Two variants add more:

    $ nix develop .#ide            # + haskell-language-server and clangd
    $ nix develop .#docs           # + Sphinx and XeLaTeX for the docs

With [direnv][15], `echo 'use flake' > .envrc && direnv allow` loads the
default shell automatically on entering the directory (`.envrc` and
`.direnv/` are git-ignored). The ghc.nix revision, and through it the
nixpkgs snapshot and the bootstrap GHC version, is pinned in `flake.lock`;
`nix flake update` advances the pins.

Filing bugs and feature requests
================================

If you've encountered what you believe is a bug in GHC, or you'd like
to propose a feature request, please let us know! Submit an [issue][10] and we'll be sure to look into it. Remember:
**Filing a bug is the best way to make sure your issue isn't lost over
time**, so please feel free.

If you're an active user of GHC, you may also be interested in joining
the [glasgow-haskell-users][11] mailing list, where developers and
GHC users discuss various topics and hang out.

Hacking & Developing GHC
========================

Once you've filed a bug, maybe you'd like to fix it yourself? That
would be great, and we'd surely love your company! If you're looking
to hack on GHC, check out the guidelines in the `HACKING.md` file in
this directory - they'll get you up to speed quickly.

Governance and Acknowledgements
===============================

GHC is a community project developed by a team of highly-talented
 researchers, individual contributors, and full-time developers. We are indebted to the
[many people](https://gitlab.haskell.org/ghc/ghc-hq/-/blob/main/team.mkd?plain=0#user-content-the-ghc-team)
whose work has brought GHC to its current state.

Some larger decisions are made by a smaller group of core contributors,
as described in our [governance documentation](https://gitlab.haskell.org/ghc/ghc-hq#ghc-governance).


[1]:  http://www.haskell.org/ghc/            "www.haskell.org/ghc/"
[2]:  https://gitlab.haskell.org/ghc/ghc/issues
        "gitlab.haskell.org/ghc/ghc/issues"
[3]:  https://gitlab.haskell.org/ghc/ghc/wikis/building
        "https://gitlab.haskell.org/ghc/ghc/wikis/building"
[4]:  http://www.haskell.org/happy/          "www.haskell.org/happy/"
[5]:  http://www.haskell.org/alex/           "www.haskell.org/alex/"
[6]:  http://www.haskell.org/haddock/        "www.haskell.org/haddock/"
[7]: https://gitlab.haskell.org/ghc/ghc/wikis/building/getting-the-sources#cloning-from-github
        "https://gitlab.haskell.org/ghc/ghc/wikis/building/getting-the-sources#cloning-from-github"
[8]:  https://gitlab.haskell.org/ghc/ghc/wikis/building/preparation
        "https://gitlab.haskell.org/ghc/ghc/wikis/building/preparation"
[9]:  http://www.haskell.org/cabal/          "http://www.haskell.org/cabal/"
[10]: https://gitlab.haskell.org/ghc/ghc/issues
        "https://gitlab.haskell.org/ghc/ghc/issues"
[11]: http://www.haskell.org/pipermail/glasgow-haskell-users/
        "http://www.haskell.org/pipermail/glasgow-haskell-users/"
[12]: https://gitlab.haskell.org/ghc/ghc/wikis/team-ghc
        "https://gitlab.haskell.org/ghc/ghc/wikis/team-ghc"
[13]: https://github.com/ghc-proposals/ghc-proposals
        "https://github.com/ghc-proposals/ghc-proposals"
[14]: https://gitlab.haskell.org/ghc/ghc.nix
        "https://gitlab.haskell.org/ghc/ghc.nix"
[15]: https://direnv.net/                "direnv.net"
