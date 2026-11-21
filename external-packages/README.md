# External package corpus

This directory holds real-world Haskell packages, checked out from
their upstream repositories or unpacked from Hackage, that are built and
tested with the compiler produced by
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
| 3 | git-annex and purescript | tier 2 plus about 30 minutes |

`--tier N` runs tiers 1 to N. Each tier has its own generated project
file (`cabal.project` for tier 1, `cabal.project.tierN` otherwise),
because cabal solves for every package in a project at once and the
unsolvable packages of a higher tier must not block a lower one. A
standalone project (see the policies) is built after the tier build,
in its own project file and build directory.

## Policies

- **Closed corpus.** Every transitive dependency, test-suite
  dependencies included, is a boot package or a package in this
  directory. The solver is the authority: if `cabal build --dry-run`
wants something from Hackage, it is added here. A package that the
compiler's own global package database already provides at the same
version is never added: cabal gives local packages the same
`-inplace` unit-id suffix that Hadrian gives in-tree ones, so the two
copies would be indistinguishable to cabal's rebuild logic. At a
different version it is fine (the corpus holds Hackage's
haddock-library 1.11.0 for pandoc while the tree ships 1.12.0).
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
  2.6.4.2, not the deprecated 2.7.0.0). Clones check out the matching
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
- **Standalone projects.** A root whose own constraints cannot be met
  inside the single-version corpus gets a cabal project of its own under
  `projects/NAME/`. purescript is one: it pins the happy build tool at
  2.0, which `allow-newer` does not relax, while the corpus holds happy
  2.2. Its manifest entries carry `project: NAME`; `add.rb --freeze
  NAME` records in `projects/NAME/cabal.project.freeze` the exact
  dependency versions that the project's own bounds select, relaxing
  only the bounds on packages the compiler ships, since those versions
  are fixed by the compiler under test; and `add.rb --fetch` vendors
  private copies of them under `projects/NAME/vendored/`, applying the
  corpus patches to copies of the same package versions. A `constraints:`
  field on an entry adds solver constraints to its project. The private
  copies are built alongside the root but not reported individually.
- **Environment.** A package's `env:` field sets variables for its test
  run, used where the package's own CI selects tests that way (shake
  skips its docs, self and selfmake tests when `CI` is set, as GitHub
  sets it).
- **Test subsets.** A package's `test_runs:` field lists argument
  strings for its test executable; the driver runs `cabal test` once per
  entry and requires all to pass. shake's harness runs one named test
  per invocation and its full suite takes minutes (three of them in
  random testing alone), so shake runs a core subset.
- **Flags.** When a package's automatic cabal flag is keyed on a bound
  that `allow-newer` relaxes (path chooses its os-string branch by
  `filepath < 1.5`), the manifest's `flags:` field forces the right
  value in the generated project files.
- **Packages are not modified.** The point is to discover which packages do
  not build or pass with this compiler, so sources stay as released, except
  where the manifest's `patched` field records a deliberate exception
  (hashable, which half the corpus sits on). One mechanical exception
  applies to every package: the names of language extensions this
  compiler has removed (listed in `lib/strip.rb`) are stripped from
  LANGUAGE pragmas, OPTIONS_GHC flags and cabal extensions fields by
  `add.rb --fetch`, because the compiler rejects the names while their
  behaviour is always on. Packages that do not build or
  whose tests fail are kept, with `expected: build-failure`, `test-failure`,
  `flaky` or `unsolvable` and the cause in the manifest. The driver reports
  them as known and fails only on unexpected results, including a known
  failure that starts passing, so that the manifest gets updated.
- **System libraries.** `flake.nix` adds zlib, SDL2, OpenSSL, fcgi and
  libmagic to the shell for the packages that need them.

## Files

- `manifest.yaml`: the single source of truth. One entry per package with
  name, version, path, tier, role, tests, source, expected, and a reason,
  note, flags, env or test_runs field where needed. `index_state` is
  written into
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
- `projects/NAME/`: a standalone project's generated `cabal.project` and
  its `cabal.project.freeze`, both committed; its clones and its
  `vendored/` copies are not.
- `patches/`: the deliberate exceptions, as diffs (see its README).

## What is committed

Only the tooling, this documentation, `manifest.yaml`, the generated
project files, the standalone projects' freeze files and `patches/` are
committed. The package sources are
not: the clones and vendored sdists live in the working tree only,
ignored by git, so that the repository's history carries neither the
code of several hundred upstream packages nor submodule entries for
them. On a
fresh clone, inside `nix develop` with network access:

    $ ruby external-packages/add.rb --fetch

clones every repository at its recorded tag or commit, vendors every
sdist and every standalone project's private copies, strips the removed
extensions and applies the patches. It skips whatever is already
present, so it is safe to rerun.

## Adding or bumping a package

Inside `nix develop`, with network access:

    $ ruby external-packages/add.rb --tier 2 --closure PKG...

adds the named packages as roots of the given tier together with every
missing package in their dependency closure, as shallow clones at the
release tags or as vendored sdists. Then run `check.rb
--write-project`, `cabal build --dry-run` for the tier, add whatever the
solver still asks for, and run the check. Record each new failure in
the manifest with a reason. `add.rb --refresh` moves multi-package
repositories forward, `add.rb --replace [--vendor] [--version V] NAME`
swaps a package's source, and `add.rb --remove NAME` drops one.

A standalone project is added by hand: write its manifest entries with
`project: NAME` and paths under `projects/NAME/`, run `add.rb --fetch`
for the clones, `add.rb --freeze NAME --build-root DIR` for the freeze
file, and `add.rb --fetch` again for the private copies. To re-freeze
after a bump, run `--freeze` again and remove the stale directories
under `projects/NAME/vendored/`.
