# Working in ghc-condensed

This is a fork of GHC (fork point 3d326d7d28, in-tree version 10.1) that
deletes language extensions one or a few at a time: the flag disappears from
the compiler, its behaviour is hard-coded on or off, and the tests, the
documentation and the external package corpus are adjusted in the same
commit. Upstream GHC will never be merged again and nothing goes upstream,
so edits to the libraries are ordinary commits.

Read first:

- `DELETED-EXTENSIONS.md`: every deletion so far, and at its top the meaning
  of each field of an entry.
- `README.md`, section "Nix": the build environment, the testsuite and the
  warnings comparison.
- `external-packages/README.md` and `external-packages/patches/README.md`:
  the corpus driver, its tiers and policies.
- `git log`: each removal commit's message is the detailed record of what
  that removal touched and why. Follow their shape for the next one.

## Ground rules

- Do not start a Hadrian build, a testsuite run or a corpus run unless
  asked. Make the change, say what is unverified and which checks a later
  build needs, and wait; the user batches several changes per build.
- When asked to build and test, run the whole set unless told otherwise:
  build, warnings comparison, a hand check with small programs, the
  testsuite, and corpus tiers 1 to 3 with their timings.
- Commit only when asked. Write the commit message in the style of the
  previous removal commits: behaviour, compiler sites, docs, testsuite,
  corpus, `DELETED-EXTENSIONS.md`, each in its own paragraph.
- Every removal adds an entry to `DELETED-EXTENSIONS.md` and bumps the count
  at its top. The Notes field is three lines at most. The Lines field counts
  `git diff --numstat` over the whole tree except `hadrian/`,
  `external-packages/` and that file; remove stray build artifacts before
  counting.
- The Stability field comes from GHC proposal 669 (Categorization of
  Language Extensions); for an Uncategorized extension add the user's guide
  `:status:` or say it has none. The other references are the GHC2021 and
  GHC2024 edition proposals (380 and 613) and the extension lifecycle
  framework (601).
- Decisions already taken, not to be reopened: RecursiveDo is hard-coded off
  (it was first done on and reverted); OverloadedStrings was withdrawn after
  measuring its blast radius; Elm was dropped from the corpus; stage-0
  warnings stay out of the baseline and the sources stay unfixed.

## Layout facts

- The 28 library submodules, nofib, `utils/hpc` and `utils/hsc2hs` are
  absorbed into the tree as plain directories; only `gmp-tarballs` and
  `libffi-clib` remain submodules. Absorbing another directory means
  extending the skip lists of the testsuite linters:
  `testsuite/tests/linters/Makefile`, `regex-linters/check-cpp.py` beside
  it, and `linters/lint-notes/Main.hs` (which reads `git ls-tree HEAD`, not
  the working tree).
- `changelog.d` entries need upstream MR and issue numbers, which fork
  changes do not have, so the fork adds none. A library API change goes in
  that library's `changelog.md` under the in-tree version.
- The compiler is built with GHC2024. Stage 0 is everything the bootstrap
  compiler builds: the stage 1 compiler itself, its library dependencies and
  the build utilities. The bootstrap compiler still has every extension, and
  gets the removed ones back through `stage0Ghc ? arg "-X..."` in
  `hadrian/src/Settings/Packages.hs` wherever a stage 0 module needs one.
  Changing that file rebuilds all of stage 0 (about 19 minutes). Hadrian
  itself is built by cabal from `hadrian/cabal.project`, which also compiles
  `libraries/ghc-platform` and `utils/ghc-toolchain` with the bootstrap
  compiler: a removed extension those sources use needs a `package` stanza
  with `ghc-options: -X...` there as well, or `hadrian/build` fails before
  any stage is built.
- Extension strips apply only to what Hadrian compiles: the compiler, the
  libraries including `Cabal-syntax` and `Cabal` (Cabal validates
  `other-extensions` against the compiler), the testsuite. Never
  cabal-install, benchmarks, test fixtures, or `hadrian/` itself, whose
  sources are bootstrap-compiled and keep their pragmas. `Win32` is
  Windows-only, unbuildable here, and has not been kept in step.

## Building and testing

Inside `nix develop`; the build root in use is `_build-lateccs`:

```
hadrian/build -j --flavour=default+late_ccs --build-root=_build-lateccs \
    > build.log 2>&1
ruby build-warnings/warnings.rb compare build-warnings/baseline.txt \
    build.log
hadrian/build test -j --flavour=default+late_ccs \
    --build-root=_build-lateccs --skip-test=mostly-static
hadrian/build test ... --test-accept --only="T1 T2"
ruby external-packages/check.rb --tier N --build-root _build-lateccs
```

- A clean build takes about 20 minutes on this 28-core machine, the
  testsuite about 10. Hadrian exits 1 on any unexpected failure. Use
  `--keep-going` after a typechecker change so every independent failure
  shows in one pass.
- Spell `--skip-test=` out: `--skip=` is ambiguous with `--skip-perf` and
  `--skip-depends`. Pass `--build-root` consistently; the flavour is cached
  per root and the wrong one is silently reused.
- After changing an interface-format `Binary` instance (anything stored in
  `.hi` files: `GHC.Iface.Syntax`, `FieldLabel`, and so on) wipe
  `_build-lateccs/stage1` first. Stale `.hi` files pass the version check
  and then panic with `Ix{Int}.index: Index ... out of range`.
- Warnings: compare the log of a plain build, never of a `test` run
  (haddock's typecheck-only pass adds about 76 selector warnings). When
  stage 0 rebuilt, up to 15 pre-existing stage-0 sites appear above the
  baseline: report them as pre-existing and move on. The 54 cpp `error:`
  lines about `HAVE_LIBZSTD` redefinition are in every log. Refresh the
  baseline with `warnings.rb extract` only when a change is meant to alter
  it, and say so in the commit.
- The testsuite comparison collapses all whitespace before comparing, so the
  `diff -uw` it prints never fails on blank lines or re-wrapping: look for
  shifted line numbers and real text. `--test-accept --only=...` rewrites
  the expected files with the raw actual output.
- Performance metrics are saved to git notes (`refs/notes/perf`) only when
  the working tree is clean, so a run on a dirty tree compares against the
  last clean-tree run. A `Metric Increase:` or `Metric Decrease:` block (one
  test per line) is read from HEAD's commit message only, so it must be
  committed before the suite runs. Size metrics named `*_dir` sit 6 to 17
  percent above the baseline because of the flavour's profiling objects;
  `*_so` is unchanged. A residency metric that was stable to 0.1 percent and
  then jumps is a leak, not noise.
- `RestartEventLogging(threaded1)` fails occasionally with an RTS assertion
  in `rts/Stats.c`; rerun before believing it.
- The `codes` test (`testsuite/tests/diagnostic-codes`) insists that every
  live diagnostic code has a test and every retired one is marked `Outdated`
  in `GHC.Types.Error.Codes`. After deleting tests, grep their stderr files
  for `[GHC-nnnnn]` and check each code still has a test.
- The haddock html and hoogle accept via `make` leaves two 15 MB runner
  binaries in `testsuite/tests/haddock/haddock_testsuite`; delete them.
  Compiling testsuite sources in place leaves untracked dump files that
  `git add -A` would commit. Check `git status` before counting lines.

### Cheap check before a build

Copy the edited compiler modules into a scratch directory as a home unit and
typecheck them against the built compiler's `ghc` package:

```
_build-lateccs/stage1/bin/ghc --make -fno-code -package ghc -XGHC2024 \
    -XNoImplicitPrelude -Wall -Wno-name-shadowing -Wno-missing-fields \
    -i<dir> -Icompiler -Irts/include \
    -I_build-lateccs/stage1/compiler/build \
    -I_build-lateccs/stage1/rts/build/include <dir>/*.hs
```

Rewrite `{-# SOURCE #-}` imports as plain imports unless the boot file is in
the set; diagnostic modules need `GHC/Types/Error/Codes.hs` with them; a
module that calls a changed signature goes in the same set as the
definition. It cannot cover AST changes, since the copies' types differ from
the package's, and it has caught indentation slips and stale variables that
no grep showed. For a grammar change, the nix store's `happy` and `alex`
regenerate the parser and lexer for the same check.

### Corpus

- Run the tiers as three invocations, `--tier 1`, `--tier 2`, `--tier 3`, on
  a fresh dist, one step at a time, nothing else running. `--all` builds the
  tier 3 project alone, so its timings compare with nothing.
- Report the tier 1 to 3 build and test timings against the previous
  fresh-dist run, recorded in the last removal commit's message. A figure
  far off means a step did not run as expected. Test steps on a fresh dist
  are slower than on a warm one because each `cabal test` reconfigures.
- Known failures are recorded in `manifest.yaml` (`expected:`). A "Failed to
  build X ... during the configure step" with no compile error is a cabal
  parallel-reconfigure race: rerun with `--only X` before believing it.
  alex's two suites race in a shared directory once in a while for the same
  reason.
- `dist/` grows by one directory per compiler build. `check.rb --clean`
  removes the other compilers' dists but then runs a tier; to clean alone,
  recompute the digest (SHA-256 of `stage1/bin/ghc` followed by
  `package.conf.d/package.cache`, first 12 hex digits) and remove the rest.
- The package directories are git-ignored, so `rg` skips them silently; use
  `grep` or a Ruby `Dir.glob` keyed on the manifest paths. Some clone
  directories are unbuilt copies (`pandoc/`, `cborg/serialise`,
  `foundation/foundation`): hits there mean nothing.
- Strip only the manifest package paths plus `projects/*/vendored/*`, as
  `add.rb` does. `Strip.tree` over the whole directory rewrites unbuilt
  sibling packages and parser fixtures. After a strip, grep the bare name
  again: a non-breaking space or an odd layout can defeat the pragma regex.
- Patch recipe: copy the package to a scratch directory, `git init`,
  reverse-apply any existing patch to recover the pristine, commit,
  re-apply, edit, and take `git diff` without the `diff --git` and `index`
  lines; verify with `git apply --check` (`-p` by directory depth) on a
  fresh copy. Same-version copies under `projects/purescript/vendored/` need
  the same hunks, or a `purescript-<pkg>.patch` when the version differs.
- Patches are diffs against the stripped tree, since `add.rb --fetch` strips
  before it applies them. After every removal run
  `ruby external-packages/audit-patches.rb`: it rebuilds each patched
  package's pristine source, strips it, applies the patch and compares with
  the working copy. A patch whose context the strip now touches, or which
  adds a pragma the compiler now rejects, is stale, and `add.rb --fetch`
  would skip it silently; regenerate it from the stripped pristine (kept
  with `--keep DIR`) and the working copy.
- `haskell-src-meta` maps template-haskell's `Extension` constructors in
  both directions and `persistent` lists required extensions by constructor:
  both patches grow with every removal. Find such code uses with a grep for
  the bare constructor name over the corpus sources.
- Implicit users of an extension are found only by building: a package under
  Haskell98 or Haskell2010 can rely on it without naming it. Expect two or
  three build rounds per tier when patching, since cabal stops at the first
  failing module per component.
- Never run cabal by hand inside a `dist/` directory, and never add a
  package the compiler's global database already provides at the same
  version.

## Removing an extension

The inventory of sites, from the removals done so far:

- Constructor in
  `libraries/ghc-internal/src/GHC/Internal/LanguageExtensions.hs` (which
  also removes it from template-haskell: note it in
  `libraries/template-haskell/changelog.md` and expect the
  `interface-stability/template-haskell-exports` stdout to change). The
  `extensionName` table in `GHC.Driver.Flags`, the edition lists and
  implications in `GHC.Driver.DynFlags`, the `-fglasgow-exts` list with
  `what_glasgow_exts_does.rst`, any lexer `ExtBits`, and `xopt_...` helpers.
- The gates. Grep the helper names as well as the extension (several call
  sites hid behind `check_data_kinds`), positional constructor patterns when
  a type loses a field, and comments and Notes with a syntax-shaped regex
  (the last `f (n+1)` lived in a Note example). A compiler module may itself
  use the feature under a pragma: the compiler is GHC2024, so an extension
  outside it needs the Hadrian stage 0 flag.
- A removed diagnostic constructor leaves its code line in
  `GHC.Types.Error.Codes` as `Outdated NNNNN`; never delete the line. A
  warning flag constructor lives in three `Flags.hs` lists plus
  `wWarningFlagsDeps`.
- `testsuite/tests/driver/T4437.hs`: `expectedCabalOnlyExtensions` gains
  every name GHC drops but Cabal's `KnownExtension` keeps.
- Pragmas: grep the bare name with no `-w` and no `\b`, since `-XName` and
  `NoName` have no word boundary; cover `.hs`, `.hsc`, `.lhs`, `.cabal`,
  GHCi `.script` files, `all.T`, `OPTIONS_GHC` pragmas, expected outputs,
  and the library test directories the testsuite runs (`base`, `ghc-heap`).
  After a strip, compare HEAD and the tree for pragmas left empty.
- Docs: the `docs/users_guide/exts/` page keeps describing the behaviour
  without its `.. extension::` directive; also the toctree, `control.rst`,
  `using-warnings.rst` and `expected-undocumented-flags.txt`.
- Testsuite: delete tests that only showed the flag off; convert a
  `compile_fail` whose program is now accepted. Pre-shift the expected
  outputs with a hunk-aware script keyed on `basename:L:C` (a multi-name
  pragma edited in place is a one-line replacement, not a deletion), then
  check by hand what the shift cannot see: `(line N)` in hint text, HIE
  query points hard-coded in the sources, `.hs:NN:` literals in tests, the
  showIface stdouts (every edition-list change shifts nine of them) and AST
  dumps, which print record fields positionally. A GHCi expectation can be
  regenerated before the build by running the new script through the old
  stage 1 ghci with `-XName` added to the testsuite's flags.
- Corpus: the `REMOVED` list (or `RENAMED`) in
  `external-packages/lib/strip.rb`, the working copies stripped, the
  `haskell-src-meta` patch, `manifest.yaml` for any new patch, and
  `audit-patches.rb` run over the result.
- A hard-coded-off removal also takes the syntax out: tokens, AST
  constructors, Template Haskell constructors, and the in-tree users
  (ghc-internal and base are Haskell2010 and may rely on the extension
  without naming it). Finding reliance on a layout or typing rule needs a
  parse or typecheck comparison, not a grep: compile each module with and
  without the flag under the bootstrap compiler and diff the dumps.
- Before a typing-level removal, measure the blast radius first: typecheck
  every testsuite source and tree module with the flag forced and count what
  breaks. That measurement is what withdrew OverloadedStrings.

## Shell and scripting pitfalls

- zsh does not word-split unquoted variables, and `${x:+a b}` is one word:
  spell flags out or pipe through `xargs`. Quote globs such as
  `--include='*.hs'`.
- Never `pgrep -f` or `pkill -f` a pattern that appears in the tool call's
  own command line; it matches the call's shell and kills it. Use pids or
  `pgrep -x`.
- Never edit a file with `ruby -i -pe` and a regex containing `#{}` or
  backslashes: a failed run truncates the file to zero bytes.
- A Ruby `<<~` heredoc strips the common indent of the replacement text too;
  use `<<-` with flush-left content, or plain strings.
- `nix develop --command ... | head` hangs when `head` exits early; write
  the output to a file instead.
- The GHC GitLab wiki and the ghc.nix pages sit behind Anubis, so fetching
  them returns a challenge page. The ghc.nix sources are in the nix store
  (`nix flake metadata` prints the path). The ghc-proposals Markdown is
  fetchable from raw.githubusercontent.com.
- `git grep` never descends into submodules.
- Reverting an old removal with `git revert --no-commit` conflicts in every
  shared list and undoes incidental work shipped in that commit; resolve
  from HEAD's text and check the staged diff against the parent shows only
  later commits' work.
