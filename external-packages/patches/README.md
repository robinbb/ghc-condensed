# Patches

Deliberate exceptions to the rule that corpus packages are not modified,
as unified diffs against the pristine sdist with paths relative to the
repository root. Each patched package carries a `patched:` line in
`manifest.yaml` saying why. `add.rb --fetch` applies them after
vendoring; by hand: `git apply external-packages/patches/NAME.patch`
from the repository root.

- `hashable.patch`: adds ghc-bignum to build-depends for GHC 9.13 and
  later, whose base no longer re-exports GHC.Num.BigNat, GHC.Num.Integer
  and GHC.Num.Natural. Without it hashable, and the roughly half of the
  corpus that depends on it, cannot be built at all.
- `dlist.patch`: test suite only. Guards its `Arbitrary1 NonEmpty` and
  `Arbitrary (NonEmpty a)` instances with
  `#if !MIN_VERSION_QuickCheck(2,19,0)`, since QuickCheck 2.19 provides
  them. The library is untouched.
- `primitive.patch`: test suite only. The same guard around its
  `Arbitrary` instances for `ByteArray`, `Down` and the Semigroup
  `First`, `Last`, `Min` and `Max` wrappers, all provided by QuickCheck
  2.19. The library is untouched.
- `data-default-class.patch`: adds base to build-depends. The 0.2.0.0
  shim depends only on data-default, and GHC 10.1 implicitly imports the
  known-names module GHC.Essentials from base in every module, so a
  package without a base dependency no longer compiles. It blocks about
  46 packages in tier 2 (the TLS chain among them).
- `encoding.patch`: hides `Data.Sequence.toList`, which containers 0.8
  (shipped with GHC 10.1) newly exports and which clashed with the
  module's `Data.Foldable (toList)` import. Blocks hledger-lib and the
  rest of the hledger family.
- `serialise.patch`: base 4.23 replaced the `KindRepTYPE RuntimeRep`
  constructor of `Type.Reflection.Unsafe` by a nullary `KindRepType`
  and added `KindRepConstraint`; the `Serialise KindRep` instance gets a
  CPP branch for base 4.23 and later. Blocks tls and with it pandoc,
  hakyll and git-annex's HTTP stack.
- `hledger-ui.patch`: one import line, `import Brick hiding (char)`, in
  `Hledger/UI/ErrorScreen.hs`. brick 3.0 added a `char` widget that
  clashes with the megaparsec `char` the module uses in its error-message
  parser. hledger-ui 1.52.4 bounds brick below 3, but hledger-iadd 1.3.23
  requires 3 and the corpus holds one brick.
- `yesod-static.patch`: depends on `ram` instead of `memory` in both
  stanzas. crypton 2.x takes its `Data.ByteArray` classes from `ram`,
  so with `memory` in scope the `ByteArrayAccess` instance of `Digest`
  is a different class and is not found. Unblocks git-annex.
- `git-annex.patch`: adds `memory` to the build-depends of the `ram`
  branch (the Memory flag is forced off in the manifest). Three modules
  import from `"memory"` unconditionally while `Utility.Hash.Crypton`
  switches to `"ram"` for crypton 1.1 and later, so under crypton 2
  that branch needs both packages. `magic` is pinned at 1.1, the newest
  release inside git-annex's own `magic <= 1.1` bound, which needs no
  source change.
- `semigroupoids.patch`: removes the `ConstrainedClassMethods` LANGUAGE
  pragma from `Data.Functor.Alt`. This compiler has no such extension
  (its behaviour is always on), so the pragma is an unsupported-extension
  error. Blocks free, lens, aeson and about a hundred packages above
  them.
- `mono-traversable.patch`: the same pragma removed from
  `Data.MonoTraversable`. Blocks conduit and everything above it.
- `haskell-src-meta.patch`: `Language.Haskell.Meta.Extensions` maps the
  haskell-src-exts `ConstrainedClassMethods` to `Nothing` and drops the
  template-haskell constructor from the reverse mapping, since this
  compiler's template-haskell no longer has it. Blocks hsx2hs, jmacro,
  interpolatedstring-perl6 and persistent-qq.
