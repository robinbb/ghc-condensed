# Patches

Deliberate exceptions to the rule that corpus packages are not modified,
as unified diffs against the pristine sdist with paths relative to the
repository root. Each patched package carries a `patched:` line in
`manifest.yaml` saying why. `add.rb --fetch` applies them after
vendoring; by hand: `git apply external-packages/patches/NAME.patch`
from the repository root.

Language extensions this compiler no longer accepts are not patched
away one package at a time: `add.rb --fetch` rewrites every package's
LANGUAGE pragmas, OPTIONS_GHC flags and cabal extensions fields
(`lib/strip.rb` lists the names). A removed extension's name is
dropped, since its behaviour is always on; a removed alias such as
Rank2Types takes the name the compiler keeps, RankNTypes. The rewritten
package means the same thing. A module-wide instance default
(OverlappingInstances, IncoherentInstances) is dropped too, but there the
package may need per-instance pragmas; those are found by building it
and reading the overlap errors, and recorded as a patch like any other
exception.

- `alex.patch`: drops the datatype context of `Data.Ranged.RangedSet.RSet`
  (`newtype DiscreteOrdered v => RSet v`), which this compiler rejects. A
  datatype context only adds a requirement at construction sites, so
  nothing else changes. alex is a build tool of half the corpus.
- `crypton-x509.patch`: the same for `Data.X509.Signed.Signed` and
  `SignedExact`.
- `wizards.patch`: one `OVERLAPPING` pragma, on the `f :<: (f :+: g)`
  instance of `System.Console.Wizard.Internal`. The cabal file enabled
  OverlappingInstances for the package; this is the only instance that
  overlaps.
- `dbus.patch`: four `OVERLAPPING` pragmas, on the `IsValue String` and
  `IsVariant String` instances of `DBus.Internal.Types` and the two
  `AutoMethod` instances for `IO` and `DBusR` of `DBus.Client`. The
  modules enabled IncoherentInstances; the most specific instance is
  enough in every case, so no instance is incoherent.
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
- `haskell-src-meta.patch`: `Language.Haskell.Meta.Extensions` maps the
  haskell-src-exts constructors of the extensions this compiler removed
  (`ConstrainedClassMethods`, `DataKinds`, `DatatypeContexts`,
  `ExplicitForAll`, `IncoherentInstances`, `MultiParamTypeClasses`,
  `OverlappingInstances`, `ParallelArrays`, `PolyKinds`, `RelaxedPolyRec`
  and `TypeInType`) to `Nothing`, and drops those constructors, `CUSKs`,
  `NullaryTypeClasses`, `AutoDeriveTypeable` and the two
  `AlternativeLayoutRule` constructors from the reverse mapping, since
  this compiler's template-haskell no longer has them. Blocks hsx2hs,
  jmacro, interpolatedstring-perl6 and persistent-qq.
- `persistent.patch`: `Database.Persist.TH.Internal` no longer lists
  `MultiParamTypeClasses` or `DataKinds` among the extensions its
  Template Haskell code requires, since template-haskell lost those
  constructors with this compiler (and both are always on). Blocks the
  yesod family, hledger-web, persistent-sqlite and git-annex. The same
  patch declares the backend parameter of
  `Database.Persist.Class.PersistStore.PersistCore`, and so of its
  associated data family `BackendKey`, at kind `Type`, and likewise the
  phantom backend parameter of
  `Database.Persist.Compatible.Types.Compatible`. The thirteen instances
  derived via `BackendKey b` in the latter module constrain `b` with
  `BackendCompatible`, a class at kind `Type`, and the via type is
  kind-checked first.
- `vector.patch`: `Data.Vector.Storable.Mutable.MVector` declares its
  state parameter at kind `Type`. The parameter is phantom (a storable
  vector holds a `ForeignPtr`), so with kinds always generalised it
  would be kind-polymorphic, and the `MVector` class instance, whose
  state parameter has kind `Type`, would not accept the type. Blocks
  a quarter of tier 1.
- `megaparsec.patch`: the hs-boot files of `Text.Megaparsec.Error` and
  `Text.Megaparsec.Internal` declare the abstract `ParseError` and
  `Reply` with the kinds of their definitions, `Type` for every
  parameter. An abstract declaration is generalised like any other, and
  the boot file's `forall k1 k2. k1 -> k2 -> Type` no longer matched the
  module.
- `bifunctors.patch`: test suite only. `OneTwoCompose`'s two functor
  parameters get their kinds written out. Generalised, the type is
  `forall k. (k -> Type) -> (Type -> Type -> k) -> ...`, and the
  derived `Functor` instance, at one instantiation of `k`, is not found
  as the superclass of the derived `Traversable` instance. GHC 9.12.2
  rejects the declaration the same way with `-XPolyKinds`.
- `aeson.patch`: `Data.Aeson.Types.Internal.Parser` quantifies the
  continuation of its field at kinds `Type -> Type` and `Type`;
  generalised, the kind variable would be existential in a newtype
  constructor, which GHC rejects. `Data.Aeson.Encoding.Internal.Encoding'`
  declares its phantom tag at kind `Type`; generalised, the encoders the
  test suite generates with Template Haskell left the tag's kind
  unsolved and the `FromPairs` instance ambiguous. Blocks a third of
  tier 1.
- `lens.patch`: `Control.Lens.Internal.Exception.handlerCatchIO` declares
  its monad parameter at kind `Type -> Type`. The boot library's
  `Control.Monad.Catch.Handler` is now kind-polymorphic, so the
  signature no longer fixed the kind that the pattern signature
  `Handling a s m` in the body needs. The `templates` test suite gives
  `T917GadtOne` and `T917GadtTwo` standalone kind signatures: the two
  kind-indexed GADTs relied on a complete user-supplied kind for their
  polymorphic recursion, and this compiler no longer detects one.
- `nothunks.patch`: the ten `deriving via` declarations whose via type is
  a bare type variable (`a`) or an application of one (`f a`) write its
  kind, `Type`. The via type is kind-checked before the instance head
  and, generalised, binds the variable at an arbitrary kind. GHC 9.12.2
  rejects the declarations the same way with `-XPolyKinds`.
- `basement.patch`: `Basement.Block.Base.Block` declares its element
  parameter at kind `Type`. It is phantom (the block is a `ByteArray#`),
  and `BlockN`, a newtype over it, derives `Eq`, `Ord`, `Show` and `Data`
  through instances that exist only at that kind. Blocks foundation,
  memory, crypton and the TLS stack.
- `crypton.patch`: `Crypto.Cipher.Types.Block.IV` declares its phantom
  cipher parameter at kind `Type`. A local binding in
  `cbcEncryptGeneric` was otherwise inferred over an `IV c` of arbitrary
  kind, with a `ByteArrayAccess (IV c)` constraint no instance matches.
- `barbies.patch`: `Barbies.Internal.Containers.Container` declares the
  kind of its barbie parameter, `(Type -> Type) -> Type`. Its `Functor`
  instance maps `first f` over `Const a`, which needs `Const` at kind
  `Type -> Type -> Type`. The kind-indexed closed families `Indexed` and
  `FilterIndex` in `Data.Generics.GenericN` get standalone kind
  signatures: their recursion at another kind relied on a complete
  user-supplied kind, which this compiler no longer detects. The class
  `Barbies.Internal.ConstraintsT.ConstraintsT` gets one as well: its
  associated type `AllT` calls the class's kind variable `k` where the
  class header calls it `kl`, which kind inference rejects as two names
  for one variable and a signature-checked class accepts.
- `linear.patch`: `Linear.V0.V0` declares its phantom element parameter
  at kind `Type`; the `Ixed` instance equates it with `IxValue (V0 a)`.
- `microlens.patch`: `Lens.Micro.Internal.foldring` quantifies the type
  variables of its result, `b` and `t`, at kind `Type`. The body retags
  a `Const r a` to `Const r t` with `phantom`, which needs `Functor` and
  `Contravariant` instances of `Const r`, both at kind `Type`.
- `mono-traversable.patch`: the eighteen `MonoFunctor`, `MonoFoldable`,
  `MonoTraversable` and `MonoPointed` instances for `Const m a`,
  `K1 i c a`, `Proxy a`, `U1 a` and `V1 a` state the kind of `a`,
  `Type`. Each instance head is generalised on its own, but the
  `Element` type instance it relies on fixes `a` at `Type`. PureScript's
  vendored copy carries the same change.
- `path.patch`: `Path`, in both `Path.Internal` and `OsPath.Internal`,
  declares its two phantom parameters at kind `Type`. `prjSomeBase` takes
  a rank-2 function over `Path b t` for every `b`, which generalised to
  every kind of `b` and no longer accepted `Path Abs t`.
- `tls.patch`: the rank-2 arguments of `Network.TLS.Crypto.withPubKeyEC`
  and `withPrivKeyEC` quantify their curve at kind `Type`. crypton's
  `EllipticCurveECDSA` class and `PublicKey` family are now
  kind-polymorphic, so the signature generalised the curve's kind, and
  the concrete curves the bodies pass no longer fit the argument.
- `yesod-core.patch`: `Yesod.Routes.Class.RenderRoute` declares its site
  parameter at kind `Type`. Its methods mention the site only through
  the associated data family `Route`, so class and family were
  generalised, and the `ParentSite (Route site) = site` instance needs
  `site` at kind `Type`.
- `commonmark-pandoc.patch`: `Commonmark.Pandoc.Cm` declares its phantom
  first parameter at kind `Type`. pandoc's CommonMark reader has
  `Typeable a` constraints on that parameter, which, once it is
  generalised, need a `Typeable k` for its kind that nothing provides.
- `aws.patch`: `Aws.DynamoDb.Core.Parser`, a copy of aeson's `Parser`,
  quantifies the continuation of its field at kinds `Type -> Type` and
  `Type`, for the reason given under `aeson.patch`; `valErr` in the same
  module quantifies the `Typeable` argument of its `Tagged` at kind
  `Type`, which `typeOf` needs. Blocks git-annex.
- `purescript-aeson.patch`, `purescript-cryptonite.patch`: PureScript's
  private copies of aeson (2.2.5.1) and cryptonite (0.30, crypton's
  ancestor) differ in version from the corpus, so `aeson.patch` and
  `crypton.patch` do not apply to them; these two carry the same kind
  pins against the copies' paths under `projects/purescript/vendored/`.
  `add.rb --fetch` applies them like any other patch, since their paths
  are relative to the repository root.
- `servant.patch`: the kind-indexed closed family `Arity'` in
  `Servant.API.TypeErrors` gets a standalone kind signature, for the
  reason given under `barbies.patch`. Blocks servant-server,
  servant-client and the other servant packages.
