# External package corpus

This directory holds real-world Haskell packages, vendored as git
submodules, that are built and tested with the compiler produced by
`hadrian/build`. The GHC testsuite exercises the compiler on small
programs; this corpus checks it against the kind of code people actually
compile with it.

## Running the check

Inside `nix develop`, after a successful `hadrian/build`:

    $ ruby external-packages/check.rb                   # tier 1
    $ ruby external-packages/check.rb --tier 2          # tiers 1 and 2
    $ ruby external-packages/check.rb --all             # every tier
    $ ruby external-packages/check.rb --build-root _build-foo

The driver finds `stage1/bin/ghc` under the build root (default
`_build`), hashes the compiler binary together with its package database,
and builds into `dist/<hash>/`. A changed compiler therefore always
builds from scratch and an unchanged one reuses everything; cabal cannot
tell the two apart on its own because the in-tree version string does not
change between local builds. `--clean` removes the dist directories of
other compilers. Logs land in `dist/<hash>/logs/`, and a machine-readable
summary in `dist/<hash>/results-tierN.json`.

No network is used: the driver passes `--offline`, and every dependency
is either a GHC boot package or part of the corpus. The Hackage index
from `cabal update` must exist, since cabal reads it while solving.

Other options: `--jobs N`, `--only pkg,...` (restrict to some roots),
`--no-tests`, `--no-keep-going`, `--write-project` (regenerate the
`cabal.project` files from the manifest and exit).

## Tiers

| Tier | Contents | Expected duration |
|---|---|---|
| 1 | feature-coverage libraries and light applications | minutes |
| 2 | pandoc, hakyll, sdl2, hledger, happstack and their closures | an hour or more |
| 3 | git-annex | tier 2 plus about 20 minutes |

`--tier N` runs tiers 1 to N. Each tier has its own generated project
file (`cabal.project` for tier 1, `cabal.project.tierN` otherwise),
because cabal solves for every package in a project at once and the
unsolvable packages of a higher tier must not block a lower one.

## Policies

- **Closed corpus.** Every transitive dependency, test-suite
  dependencies included, is a boot package or a package in this
  directory. The solver is the authority: if `cabal build --dry-run`
  wants something from Hackage, it is added here. Packages that the
  compiler's own global package database already provides (the boot
  packages, haddock-library, haddock-api) are never added: cabal gives
  local packages the same `-inplace` unit-id suffix that Hadrian gives
  in-tree ones, so the two copies are indistinguishable to cabal's
  rebuild logic. After removing such a package, delete `dist/`.
- **Roots and deps.** A *root* is a package chosen for coverage; its
  test suites run. A *dep* is only built. Running a dep's tests would
  pull in its own test dependencies and so on without end.
- **Tests.** Only cabal `test-suite` stanzas that can be satisfied inside
  the Nix shell are run. Suites that need doctest, hint,
  inspection-testing (GHC-API packages that break on development
  compilers), a display, node, or external tools are skipped, with the
  reason recorded in the manifest. Packages whose tests run through the
  executable instead of a test suite (git-annex) are build-only.
- **Versions.** Each package is pinned at its latest Hackage release that
  Hackage's preferred-versions list does not deprecate (so network-uri is
  2.6.4.2, not the deprecated 2.7.0.0). Submodules check out the matching
  git tag. Where a repository hosts several packages, `add.rb --refresh`
  moves it once to the newest tag any of its packages asks for. When no
  tag exists, or the tag's cabal file carries a different version, the
  package is vendored as an unpacked sdist under `vendored/`, as are
  packages whose repositories need nested submodules (digest) or
  generated sources (skylighting), which the sdist carries.
- **Bounds.** `allow-newer: all` relaxes every upper bound: the corpus
  holds exactly one version of each package, so a bound can only accept
  or reject the one plan there is, and the point is to compile the code
  with this compiler, not to validate bounds. Lower bounds still apply.
  A package that genuinely fails against a newer dependency shows up as
  a build failure and is recorded as such.
- **Flags.** When a package's automatic cabal flag is keyed on a bound
  that `allow-newer` relaxes (path chooses its os-string branch by
  `filepath < 1.5`), the manifest's `flags:` field forces the right
  value in the generated project files.
- **Packages are not modified.** The point is to discover which packages do
  not build or pass with this compiler, so sources stay as released, except
  where the manifest's `patched` field records a deliberate exception
  (hashable, which half the corpus sits on). Packages that do not build or
  whose tests fail are kept, with `expected: build-failure`, `test-failure`,
  `flaky` or `unsolvable` and the cause in the manifest. The driver reports
  them as known and fails only on unexpected results, including a known
  failure that starts passing, so that the manifest gets updated.
- **System libraries.** `flake.nix` adds zlib, SDL2, OpenSSL, fcgi and
  libmagic to the shell for the packages that need them.

## Files

- `manifest.yaml`: the single source of truth. One entry per package with
  name, version, path, tier, role, tests, source, expected, and a reason,
  note or flags field where needed. `index_state` is written into
  the project files.
- `cabal.project`, `cabal.project.tier2`, `cabal.project.tier3`:
  generated from the manifest by `check.rb`; committed so that plain
  `cabal` commands work in this directory too. Do not edit by hand.
- `check.rb`: the driver described above.
- `add.rb`: adds packages. `lib/hackage.rb` reads the local Hackage
  index (cached in `dist/hackage-index.cache`); `lib/manifest.rb` reads
  and writes the manifest.
- `vendored/`: unpacked sdists for packages without a git repository
  (not committed; see below).
- `patches/`: the deliberate exceptions, as diffs (see its README).

## What is committed

Only the tooling, this documentation, `manifest.yaml`, the generated
project files and `patches/` are committed. The package sources are
not: submodules and vendored sdists live in the working tree only, so
that the repository's history carries neither the code of several
hundred upstream packages nor `.gitmodules` entries for them. On a
fresh clone, inside `nix develop` with network access:

    $ ruby external-packages/add.rb --fetch

adds every submodule at its recorded tag, vendors every sdist, and
applies the patches. It skips whatever is already present, so it is
safe to rerun.

## Adding or bumping a package

Inside `nix develop`, with network access:

    $ ruby external-packages/add.rb --tier 2 --closure PKG...

adds the named packages as roots of the given tier together with every
missing package in their dependency closure, as submodules at the
release tags (shallow) or as vendored sdists. Then run `check.rb
--write-project`, `cabal build --dry-run` for the tier, add whatever the
solver still asks for, and run the check. Record each new failure in
the manifest with a reason. `add.rb --refresh` moves multi-package
repositories forward, `add.rb --replace [--vendor] [--version V] NAME`
swaps a package's source, and `add.rb --remove NAME` drops one.
