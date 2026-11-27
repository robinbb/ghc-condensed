# Patches

Deliberate exceptions to the rule that corpus packages are not modified, as
unified diffs against the pristine sdist with paths relative to the
repository root. Patch files are stored byte for byte (`.gitattributes`), so
a patch against a package whose sources have CRLF line endings, as
JuicyPixels does, applies on any checkout. Each patched package carries a
`patched:` line in `manifest.yaml` saying why. `add.rb --fetch` applies them
after vendoring; by hand: `git apply external-packages/patches/NAME.patch`
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
exception. The strip runs before the patches, so a patch is a diff against
the stripped tree: its context never shows a stripped name, and a removal
whose strip touches a patch's context or whose name a patch adds must
refresh that patch, or `add.rb --fetch` skips it with a one-line message.
`audit-patches.rb`, beside `check.rb`, simulates that fetch for every patch;
run it after each removal.

- `alex.patch`: drops the datatype context of `Data.Ranged.RangedSet.RSet`
  (`newtype DiscreteOrdered v => RSet v`), which this compiler rejects. A
  datatype context only adds a requirement at construction sites, so
  nothing else changes. alex is a build tool of half the corpus.
- `crypton-x509.patch`: the same for `Data.X509.Signed.Signed` and
  `SignedExact`.
- `regex-tdfa.patch`, `lifted-base.patch`, `ShellCheck.patch`,
  `happy-lib.patch`, `network-bsd.patch`, and the second hunk of
  `alex.patch`: `do` blocks that began at the indentation of their enclosing
  block, which the Haskell 98 layout relaxation `NondecreasingIndentation`
  allowed, are indented two columns further, as the Haskell 2010 layout rule
  requires and this compiler now enforces. regex-tdfa and alex enabled the
  extension in their cabal files and network-bsd in a pragma; lifted-base,
  ShellCheck and happy-lib wrote the pattern in Haskell 98 mode, where it
  was on by default. The blocks were found by parsing every candidate module
  with the rule on and off and comparing the parses, and each re-indented
  module parses with the rule off exactly as the original did with it on. In
  network-bsd a `>>= peek` line at the blocks' shared column had closed the
  inner block through the layout rule's parse-error clause and so applied to
  that block alone; it now sits one column short of the inner block, which
  keeps that reading. `purescript-happy-lib.patch` is the same change for
  PureScript's private happy-lib 2.0.2.
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
  source change. `Command.Import.optParser` builds its options with `<$>`
  and `<*>` rather than do-notation; this compiler has no `ApplicativeDo`.
- `haskell-src-meta.patch`: `Language.Haskell.Meta.Extensions` maps the
  haskell-src-exts constructors of the extensions this compiler removed
  (`ConstrainedClassMethods`, `DataKinds`, `DatatypeContexts`,
  `ExplicitForAll`, `IncoherentInstances`, `MultiParamTypeClasses`,
  `OverlappingInstances`, `ParallelArrays`, `PolyKinds`, `RelaxedPolyRec`,
  `TypeInType`, `DeriveDataTypeable`, `RankNTypes`, `ParallelListComp`,
  `ScopedTypeVariables`, `NPlusKPatterns`, `NondecreasingIndentation`,
  `DisambiguateRecordFields`, `ExplicitNamespaces`, `BinaryLiterals`,
  `Arrows`, `LambdaCase` and `MonomorphismRestriction`) to `Nothing`, and
  drops those constructors, `CUSKs`, `StarIsType`, `DeepSubsumption`,
  `NullaryTypeClasses`, `AutoDeriveTypeable`, `ApplicativeDo`,
  `QualifiedDo`, `StandaloneKindSignatures`, `HexFloatLiterals`,
  `NumDecimals`, `NumericUnderscores`, `MultilineStrings`,
  `TraditionalRecordSyntax` and the two `AlternativeLayoutRule` constructors
  from the reverse mapping, since this compiler's template-haskell no longer
  has them. `Language.Haskell.Meta.Syntax.Translate` builds `DoE` without
  the module qualifier that template-haskell dropped with `QualifiedDo`.
  Blocks hsx2hs, jmacro, interpolatedstring-perl6 and persistent-qq.
- `attoparsec.patch`, `colour.patch`, `happstack-server.patch`,
  `hspec-core.patch`, `old-time.patch`, `safe.patch`, `shake.patch`,
  `shelly.patch`, `syb.patch`, `zlib.patch`, and the later hunks of
  `aeson.patch`, `generic-deriving.patch`, `megaparsec.patch`,
  `optparse-applicative.patch`, `reflection.patch`, `regex-tdfa.patch`,
  `shakespeare.patch`, `ShellCheck.patch`, `th-abstraction.patch` and
  `vector.patch`: bindings without type signatures that the monomorphism
  restriction kept monomorphic and that this compiler, which has no such
  restriction, generalises into an ambiguous type. Each gets the type it
  had: attoparsec's buffer generation counter `1 :: Int`; colour's
  `quantize` bounds `l, h :: a` and `toSRGBBounded` scale `m :: b` with its
  helper `f :: b -> a`; happstack-server's six `cookiesParser` sub-parsers
  as `GenParser Char st` values; hspec-core's saved failure report at `Maybe
  FailureReport`; old-time's month and year adjustment `tmp :: (Month,
  Int)`; safe's `toEnumMay` value `r :: a`; shake's `unsafeBinarySplit`
  value `v :: a`, its `(String, [String])` instance's list `:: [String]` and
  the `(a,b) = cmdString` and `cmdResult` pairs of
  `Development.Shake.Command` at their instance types; shelly's `shelly_dir
  :: FilePath`; syb's `allButString :: ReadP a'` and the where-bound workers
  of its unit tests; zlib's test length `len :: Int64`; aeson's test helper
  `omf :: Maybe a`; generic-deriving's `toEnumDefault` enumeration `l ::
  [Rep a ()]`; megaparsec's `dbg` logger `l :: DbgItem s e a -> String`
  under an instance signature that scopes `a`, and slicer `unfold :: s ->
  [Token s]`; optparse-applicative's test parser `p :: Parser [String]`;
  reflection's `s :: Proxy (StableBox w0 w1 a)`; regex-tdfa's bound counts
  `read ... :: Int`; shakespeare's six `parseDeref` sub-parsers as
  `UserParser a` values; ShellCheck's `minLine, maxLine :: Int`, `Array Node
  [Node]` dominator arrays, `checkElement` with its `literalEquals` at
  `Writer [TokenComment]`, and the executable's `printErr :: String ->
  ExceptT Status IO ()`; th-abstraction's `renamedTyvars ::
  [TyVarBndrUnit]`; vector's benchmark `pack_index` and `enumerate` counting
  at `Int`. The patches of attoparsec, colour, reflection, regex-tdfa, safe,
  syb, th-abstraction, vector and zlib apply to PureScript's same-version
  copies too. Between them they blocked 89 of tier 1's 154 packages. Tier 2
  adds `bitvec.patch`, `cassava-megaparsec.patch`, `clientsession.patch`,
  `cmdargs.patch`, `commonmark-extensions.patch`, `conduit.patch`,
  `crypto-api.patch`, `crypto-pubkey-types.patch`, `Decimal.patch`,
  `doclayout.patch`, `haddock-library.patch`, `half.patch`,
  `hashtables.patch`, `hledger.patch`, `hledger-flow.patch`,
  `hledger-iadd.patch`, `hledger-lib.patch`, `hledger-web.patch`,
  `jira-wiki-markup.patch`, `pandoc.patch`, `path-pieces.patch`,
  `SHA.patch`, `streaming-commons.patch`, `tagsoup.patch` and `typst.patch`,
  and later hunks of `cassava.patch`, `commonmark.patch`, `crypton.patch`,
  `crypton-x509.patch`, `cryptonite.patch`, `encoding.patch`,
  `hedgehog.patch`, `JuicyPixels.patch`, `lucid.patch`, `persistent.patch`,
  `tls.patch`, `wizards.patch` and `x509.patch`. Tier 3 adds
  `criterion.patch`, `crypton-conduit.patch` and `statistics.patch`, and
  later hunks to `git-annex.patch`. Their bindings get the types they had:
  bitvec's words `w :: Word`; cassava's generic record parsers under
  instance signatures that scope `p`; cassava-megaparsec's `normalChar,
  escapedDq :: Parser Word8`; clientsession's generated bytes at
  `(S.ByteString, ChaChaDRG)`; cmdargs' `recompose` result pinned with
  `asTypeOf`; commonmark's attribute function `f :: a -> a`;
  commonmark-extensions' footnote data defaulted at `(Int, Text)`; conduit's
  mtl-instance test conduits at `ConduitT () Int (Either DummyError) ()` and
  `ConduitT () Void (W.Writer [Int]) ()`; crypto-api's digests `res :: d`,
  initialisation vectors `iv :: IV k`, key lengths at `Tagged k BitLength`,
  CMAC subkeys `k1, k2 :: IV k` and HMAC digest `res :: d`;
  crypto-pubkey-types' `nints :: [Word8]`; crypton's and cryptonite's
  `polyKey :: ScrubbedBytes`, `ti :: ScrubbedBytes`, `output :: output`,
  `bytes :: bytearray`, `bs :: ba` and derived `key :: ScrubbedBytes`,
  crypton's Salsa and ChaCha test chunks at `(ByteString, State)`,
  cryptonite's CBC and CFB blocks pinned with `asTypeOf input` as crypton's
  already are, and crypton's CCM tag `t :: Bytes` and HMAC DRG digests at
  `Digest hash`; crypton-conduit's `nonce :: ByteString`; criterion's
  decoded reports at `Either String ReportFileContents`; git-annex's string
  constants `escq`, `httpprefix` and `gitdirprefix` at `String`, test path
  `p :: Maybe FilePath`, content length `len :: Maybe Integer`, point-free
  config readers `getcfg :: Repo -> String` and `getmaybe :: ConfigKey ->
  Maybe String`, prompter `run :: m a -> m a` and `cleanup :: IO ()`, WebDAV
  export path `p :: String`, SSH `port :: Maybe Integer`, metadata log `s ::
  S.Set (LogEntry MetaData)`, logged bytes `0 :: Integer`, simulation
  `coinflip, notted, combineand :: Bool` and `go :: [Word8] -> Int -> StdGen
  -> ([Word8], StdGen)`, webapp idents `ident :: Text` (three of them) and
  `postsetup :: Remote -> Handler a`, and the test suite's sixteen
  `conflictor`, `subdir`, `dir`, `dest` and `subfile` names at `FilePath`;
  Decimal's `n2 :: b` and `ub, lb :: Integer`; doclayout's `pa :: a`;
  encoding's UTF-8 code points `v :: Int`; haddock-library's `nlList ::
  Parser [Text]`; half's decoding constants at `Integer` and sign bit `s ::
  Int`; hashtables' `f :: (k, v) -> ST s Int`; hedgehog's `mx :: f a`;
  jira-wiki-markup's `blockEnd :: JiraParser String`; hledger's setup
  failure action and message at `IO ()` and `String`, rewrite counts at
  `(Int, Int)` and compound report header row at `[Spr.Cell Spr.NumLines
  T.Text]`; hledger-flow's test literals at `[T.Text]`, `[String]` and
  `Map.Map String [String]`; hledger-web's register `balancelabel ::
  String`; hledger-iadd's option parser `parser :: OParser a`; hledger-lib's
  `maxlag :: Integer` and included-file reader `r :: Reader m`; JuicyPixels'
  `maxVal :: a`; lucid's test documents at `Html ()`; pandoc's Docx style
  maps at `(CharStyleNameMap, ParaStyleNameMap, TableStyleNameMap)`,
  DocBook's `skip` at `DB m Blocks` and `DB m Inlines`, Pod's `close` at
  `PodParser m T.Text`, Creole's `rowEnd` and `cellEnd` at `CRLParser m
  Char`, Shared's `borderParts :: Doc Text`, Docx's `relIds :: [Int]`, the
  DocBook writer's `mTitleBs :: Maybe (DB m (Doc Text))`, ConTeXt's
  `section, chapter :: Doc Text`, AsciiDoc's `spanFactor :: Doc Text`,
  ANSI's `render :: D.Doc Text -> D.Doc Text` and title block `most :: D.Doc
  Text`, and Org's `endOfCitation :: OrgParser m Char` and include bounds
  `startLine, endLine :: Maybe Int`; path-pieces' `n :: Maybe a`;
  persistent's `x :: (a, b)` and `colCountFst :: Int` in RawSql's pair
  instance and `n :: Fixed a` in PersistFieldSql's Fixed instance; SHA's
  `lenBits :: Word64`; statistics' kernel density `h, a :: v Double`;
  streaming-commons' stream getters at `Maybe Handle -> IO stdin`; tagsoup's
  `charsStr` and `charsEntsStr` returning `str`; tls's MAC function `macF ::
  BA.ScrubbedBytes -> ByteString -> BA.ScrubbedBytes` and input `msg ::
  ByteString`; typst's regex match at `(Text, Text, Text, [Text])`; x509's
  and crypton-x509's `nints :: [Word8]`; wizards' initial state annotated
  `PureState`. The patches of bitvec, half, streaming-commons and tagsoup
  apply to PureScript's same-version copies too; PureScript's cryptonite
  copy, an sdist whose layout differs from the corpus checkout, gets the
  same hunks through `purescript-cryptonite.patch`. In tier 2 they broke 29
  builds and two test suites and blocked 80 more of its 340 packages on the
  first run, ten builds and a test suite on the second, four builds and the
  same test suite on the third, four builds and crypton's test suite on the
  fourth, two builds on the fifth, tls twice more, on the eighth the two
  executables that had waited behind it, hledger and pandoc, on the ninth
  pandoc's writers and hledger-web, on the tenth pandoc's last three
  modules, and on the eleventh pandoc's tests and hakyll. Tier 3 then broke
  four builds (crypton-conduit, dbus, microstache, statistics) and blocked
  criterion, fdo-notify, yesod-static and git-annex behind them, and
  criterion and then git-annex, once reachable, needed rounds of their own;
  PureScript's 131 packages built unchanged.
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
  rejects the declaration the same way with `-XPolyKinds`. `F`,
  `OneTwoComposeFam` and `ComplexConstraintFam` also spell their kinds
  `Type`, for the reason given under `constraints.patch`.
- `aeson.patch`: `Data.Aeson.Types.Internal.Parser` quantifies the
  continuation of its field at kinds `Type -> Type` and `Type`;
  generalised, the kind variable would be existential in a newtype
  constructor, which GHC rejects. `Data.Aeson.Encoding.Internal.Encoding'`
  declares its phantom tag at kind `Type`; generalised, the encoders the
  test suite generates with Template Haskell left the tag's kind
  unsolved and the `FromPairs` instance ambiguous. Blocks a third of
  tier 1. The two parsers of `tests/UnitTests/MonadFix.hs` tie their knots
  with `mfix` rather than `mdo`; this compiler has no recursive
  do-notation.
- `lens.patch`: `Control.Lens.Internal.Exception.handlerCatchIO` declares
  its monad parameter at kind `Type -> Type`. The boot library's
  `Control.Monad.Catch.Handler` is now kind-polymorphic, so the
  signature no longer fixed the kind that the pattern signature
  `Handling a s m` in the body needs. The `templates` test suite gives
  `T917GadtOne` and `T917GadtTwo` standalone kind signatures: the two
  kind-indexed GADTs relied on a complete user-supplied kind for their
  polymorphic recursion, and this compiler no longer detects one.
  `Language.Haskell.TH.Lens` drops the `_MDoE` and `_RecS` prisms and gives
  `_DoE` the one-field `DoE`; template-haskell lost those constructors and
  the module qualifier of `DoE` with this compiler, which has neither
  recursive nor qualified do-notation. The same hunks apply to PureScript's
  private copy of lens 5.3.6.
- `nothunks.patch`: the ten `deriving via` declarations whose via type is
  a bare type variable (`a`) or an application of one (`f a`) write its
  kind, `Type`. The via type is kind-checked before the instance head
  and, generalised, binds the variable at an arbitrary kind. GHC 9.12.2
  rejects the declarations the same way with `-XPolyKinds`.
- `basement.patch`: `Basement.Block.Base.Block` declares its element
  parameter at kind `Type`. It is phantom (the block is a `ByteArray#`),
  and `BlockN`, a newtype over it, derives `Eq`, `Ord`, `Show` and `Data`
  through instances that exist only at that kind. Blocks foundation,
  memory, crypton and the TLS stack. `Basement.Monad.PrimVar` spells its
  kind `Type`, for the reason given under `constraints.patch`.
- `crypton.patch`: `Crypto.Cipher.Types.Block.IV` declares its phantom
  cipher parameter at kind `Type`. A local binding in `cbcEncryptGeneric`
  was otherwise inferred over an `IV c` of arbitrary kind, with a
  `ByteArrayAccess (IV c)` constraint no instance matches. Its
  `tests/PubKey/MLKEMSpec.hs` and `MLDSASpec.hs` fix the `p` quantified in
  `withSet` at kind `Type`; `PolyKinds`, always on with this compiler, would
  otherwise generalise it, and the continuation could not be applied at
  `MLKEM512`.
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
  `Linear.V`'s `D`, `SD` and `PD` spell their kinds `K.Type`, for the
  reason given under `constraints.patch`; the module imports
  `Language.Haskell.TH`, whose `Type` would clash.
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
  `crypton.patch` do not apply to them; these two carry the same kind pins
  against the copies' paths under `projects/purescript/vendored/`. `add.rb
  --fetch` applies them like any other patch, since their paths are relative
  to the repository root. `purescript-cryptonite.patch` also carries the
  type annotations that `cryptonite.patch` adds for the removal of the
  monomorphism restriction.
- `servant.patch`: the kind-indexed closed family `Arity'` in
  `Servant.API.TypeErrors` gets a standalone kind signature, for the
  reason given under `barbies.patch`. Blocks servant-server,
  servant-client and the other servant packages.
- `constraints.patch`: `Data.Constraint.Dict` and
  `Data.Constraint.Forall.inst1` spell the kind `Type` where they wrote
  `*`. This compiler never reads `*` as a kind, so a Haskell2010 module
  that did so writes `Type` and imports `Data.Kind` if nothing else
  brought it into scope; the other patches below that cite this one do
  the same. Blocks lens and everything above it.
- `contravariant.patch`: `Data.Functor.Contravariant.Generic.Swizzle`
  spells its kinds `Type`, for the reason given under
  `constraints.patch`. Blocks the semigroupoids family.
- `monad-control.patch`: the associated types `StT` and `StM` of
  `Control.Monad.Trans.Control` spell their result kind `Type`, for the
  reason given under `constraints.patch`. Blocks lifted-base and the
  conduit family.
- `quickcheck-classes-base.patch`: `Proxy1` and `Proxy2` in
  `Test.QuickCheck.Classes.Base` spell their parameter kinds `Type`, for
  the reason given under `constraints.patch`.
- `reflection.patch`: the `fast` implementation of `Data.Reflection`
  spells its kind annotations `K.Type`, for the reason given under
  `constraints.patch`; the module imports `Language.Haskell.TH`, whose
  `Type` would clash with an unqualified import. Blocks lens.
- `th-abstraction.patch`: test suite only. `Types` and `Main` spell
  their kinds `Type`, inside a declaration quote too, for the reason
  given under `constraints.patch`.
- `generic-deriving.patch`: test suite only. `T68Spec` and
  `ExampleSpec` spell their kinds `Type`, for the reason given under
  `constraints.patch`.
- `profunctors.patch`: the associated types `Rep` and `Corep` of
  `Data.Profunctor.Rep` spell their kinds `Type`, for the reason given
  under `constraints.patch`. Blocks adjunctions, lens and the rest of the
  profunctor tower.
- `adjunctions.patch`: the associated type `Rep` of both
  representable classes and `GRep'` spell their kinds `Type`, for the
  reason given under `constraints.patch`.
- `cassava.patch`: `Data.Csv.Conversion`'s `unParser` signature and
  `Proxy` spell their kinds `Type`, for the reason given under
  `constraints.patch`.
- `cereal.patch`: `Data.Serialize.Tagged` spells its parameter kind
  `Type`, for the reason given under `constraints.patch`. Blocks bytes
  and linear.
- `http-api-data.patch`: the classes `GToForm` and `GFromForm` of
  `Web.Internal.FormUrlEncoded` spell their kinds `Type`, for the reason
  given under `constraints.patch`. Blocks servant.
- `JuicyPixels.patch`: the associated types `PixelBaseComponent` and
  `StorageType` spell their result kind `Type`, for the reason given
  under `constraints.patch`. Blocks pandoc.
- `bytes.patch`: the associated types of `Data.Bytes.Get` and the
  families of `Data.Bytes.Signed` spell their result kind `Type`, for the
  reason given under `constraints.patch`. Blocks linear.
- `th-expand-syns.patch`: the `ForAll` synonym of `testing/Types.hs`
  declares its variable at kind `Type`, which `PolyKinds`, always on with
  this compiler, would otherwise generalise, and `testing/Main.hs` splices
  `StarT` for the kind `*` in the quoted type it compares against;
  `StarIsType` is off with this compiler.
- `invariant.patch`: `test/THSpec.hs` writes `Type` for `*` in three kind
  signatures; `StarIsType` is off with this compiler.
  `purescript-invariant.patch` is the same hunk for PureScript's private
  copy of invariant 0.6.5.
- `microlens-th.patch`: `test/T917.hs` writes `Type` for `*` in five kind
  annotations and `test/templates.hs` in one; `StarIsType` is off with this
  compiler.
- `psqueues.patch`: `tests/Data/PSQ/Class.hs` writes `Type` for `*` in the
  kinds of the `PSQ` class; `StarIsType` is off with this compiler.
- `th-lift.patch`: `t/Foo.hs` drops the datatype context of `Foo`;
  `DatatypeContexts` is removed from this compiler, and `Lift` deriving
  never needed it.
- `math-functions.patch`: `tests/Tests/Helpers.hs` declares the phantom
  parameter of `T` at kind `Type`, since `typeName` applies `typeOf` to it;
  `PolyKinds`, always on with this compiler, would otherwise generalise it.
- `commonmark.patch`: `Commonmark.Html` declares the phantom parameter of
  `Html` at kind `Type`, so that `IsBlock (Html a) (Html a)` stays more
  specific than the `OVERLAPPABLE` instance of `Commonmark.Types`;
  `PolyKinds`, always on with this compiler, would otherwise generalise it,
  and commonmark-extensions' tests, which choose between the two, were
  refused for overlap.
- `cryptonite.patch`: as `crypton.patch`, `Crypto.Cipher.Types.Block.IV`
  declares its phantom cipher parameter at kind `Type`. Only the x509 test
  suite needs cryptonite; PureScript's private copy already had the change
  from `purescript-cryptonite.patch`.
- `safecopy.patch`: `Data.SafeCopy.Instances` fixes the `SafeCopy (Fixed a)`
  instance and the `typeName` helpers at kind `Type`; `Fixed` is
  kind-polymorphic in base, and `typeOf1` wants a parameter of kind `Type`.
  Only the acid-state test suites need safecopy.
- `MissingH.patch`: `Data.BinPacking` drops the datatype context of
  `BinPackerError`, and `System.IO.HVFS.Combinators` those of `HVFSReadOnly`
  and `HVFSChroot`; `DatatypeContexts` is removed from this compiler.
- `acid-state.patch`: `test/Data/Acid/StateMachineTest.hs` writes `Type` for
  `*` in four kind annotations; `StarIsType` is off with this compiler.
- `x509.patch`: `Data.X509.Signed` drops the datatype contexts of `Signed`
  and `SignedExact`; `DatatypeContexts` is removed from this compiler. Only
  its own test suite needs the package built.
- `regex-tdfa.patch`, later hunks: the five `mdo` blocks of
  `Text.Regex.TDFA.CorePattern` and `.TNFA` tie their knots with `mfix`
  over the one variable each uses before binding it; this compiler has no
  recursive do-notation. The same hunks apply to PureScript's private copy
  of regex-tdfa 1.3.2.7. Blocks tasty-quickcheck and so most tier 1 test
  suites, and ShellCheck, hledger, hakyll, typst and git-annex.
- `parallel.patch`: `Control.Parallel.Strategies.parListChunk` ties its
  knot with `mfix` rather than `mdo`; this compiler has no recursive
  do-notation.
- `lucid.patch`: the MonadFix test of `test/Main.hs` ties its knot with
  `mfix` rather than `mdo`; this compiler has no recursive do-notation.
- `hedgehog.patch`: `Hedgehog.Internal.Gen.element` and `element_` and the
  `genCommands` generator of the `Applicative` test write `<$>` and `<*>`
  for what `ApplicativeDo` desugared from do-notation, so they consume
  their seeds and shrink exactly as before; this compiler has no
  `ApplicativeDo`.
- `servant-client-core.patch`:
  `Servant.Client.Core.MultiVerb.ResponseUnrender.fromSomeClientResponse`
  maps over its `Alternative` with `<$>` rather than do-notation, since
  this compiler has no `ApplicativeDo`.
- `yesod.patch`, `shakespeare.patch`: `Yesod.Default.Util` and
  `Text.Hamlet` build `DoE` without the module qualifier field that
  template-haskell dropped with `QualifiedDo`.
- `text-builder-linear.patch`: the integer literals that
  `Data.Text.Builder.Linear.Dec.Bounded` and `.Unbounded` wrote in
  scientific notation (`1e9`, `1e18`, `1e38`) are written in digits, and
  the test suite, which the corpus does not run, computes its powers of
  ten with `^`; this compiler has no `NumDecimals`, so a literal with an
  exponent is always fractional. text-builder, text-builder-core,
  text-ansi and yamlet depend on it.
- `optparse-applicative.patch`: test suite only. `tests/Examples/Cabal.hs`
  writes its seven `proc` blocks with the `&&&`, `>>>` and `arr`
  combinators of the package's own `Options.Applicative.Arrows` interface,
  which the example exists to exercise; this compiler has no arrow
  notation. Each block ran its parsers in order and returned a constructor
  applied to their results, and the arrow's composition runs effects in
  sequence, so the same parsers paired with `&&&` and fed to `arr` are the
  same parser: compiled with the stage 1 compiler, the two versions render
  the same help text and parse results, byte for byte, over 108 argument
  lists under four preference sets. `purescript-optparse-applicative.patch`
  is the same hunk for PureScript's private copy of optparse-applicative
  0.18.1.0.
