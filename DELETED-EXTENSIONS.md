# Deleted language extensions

**44 language extensions deleted.**

This fork deletes language extensions rather than deprecating them: the flag
disappears from the compiler, its behaviour is hard-coded, and the tests,
documentation and external package corpus are adjusted in the same commit.
The entries below are alphabetical. For each extension it gives:

- **Category**: the part of the language the extension belongs to: Syntax,
  Literals, Types, Type Signatures, Classes & Instances, Deriving Mechanism
  or Other.
- **Hard-coded**: On, Off or N/A: whether the behaviour the extension
  switched on is now always on, always off, or does not apply because the
  extension was a deprecated alias or a no-op.
- **Editions**: the language editions that enabled the extension before its
  deletion (Haskell98, Haskell2010, GHC2021, GHC2024), taken from
  `languageExtensions` in `GHC.Driver.DynFlags` at the fork point, commit
  3d326d7d28.
- **Lines**: lines added and deleted by the deletion commit, and the net
  change, counted over the whole repository except `hadrian/`,
  `external-packages/` and this file. Where one commit deleted several
  extensions, each of them shows the commit's total. A positive net change
  is explained in a few words.
- **Stability**: the category assigned by GHC proposal 669
  ([Categorization of Language Extensions][669], accepted 2025-08-07):
  Stable, Legacy, Experimental or Deprecated, or Uncategorized where that
  proposal defers the decision. For an uncategorized extension the
  `:status:` field of the user's guide at the fork point is given as well.
- **Notes**: in at most three lines, what the hard-coded behaviour amounts
  to and why it was fixed that way; the reasons are the author's best
  guesses and may be revised.

`AlternativeLayoutRule`

- Category: Syntax.
- Hard-coded: N/A.
- Editions: none.
- Lines: +52 −621, net −569 (shared with AlternativeLayoutRuleTransitional
  and PolymorphicComponents).
- Stability: Deprecated.
- Notes: The alternative layout algorithm was deleted; GHC has one layout
  rule. An unfinished, undocumented experiment that no code used.

`AlternativeLayoutRuleTransitional`

- Category: Syntax.
- Hard-coded: N/A.
- Editions: none.
- Lines: +52 −621, net −569 (shared with AlternativeLayoutRule and
  PolymorphicComponents).
- Stability: Deprecated.
- Notes: As for AlternativeLayoutRule: the transitional variant of the same
  unfinished experiment.

`ApplicativeDo`

- Category: Syntax.
- Hard-coded: Off.
- Editions: none.
- Lines: +403 −4774, net −4371 (shared with QualifiedDo).
- Stability: Uncategorized; the user's guide gives no stability status.
- Notes: A `do` block always desugars through `>>=` and `>>`, never `<$>`
  and `<*>`, so do-notation needs `Monad`; independent statements are
  written applicatively by hand. Four corpus packages used it.

`AutoDeriveTypeable`

- Category: Deriving Mechanism.
- Hard-coded: N/A.
- Editions: none.
- Lines: +30 −39, net −9.
- Stability: Uncategorized; the user's guide lists the flag as undocumented.
- Notes: A no-op since GHC 7.10, when every type gained a `Typeable`
  instance; it survived only so that old pragmas parsed.

`BinaryLiterals`

- Category: Literals.
- Hard-coded: On.
- Editions: GHC2021, GHC2024.
- Lines: +119 −429, net −310 (shared with HexFloatLiterals, NumDecimals and
  NumericUnderscores).
- Stability: Stable.
- Notes: An integer literal may always be written in binary, as `0b1011`.
  GHC2021 enables it; the only program it changes is one that meant `0b1`
  as `0 b1`, which no one wrote on purpose.

`ConstrainedClassMethods`

- Category: Classes & Instances.
- Hard-coded: On.
- Editions: GHC2021, GHC2024; also implied by MultiParamTypeClasses.
- Lines: +36 −154, net −118.
- Stability: Stable.
- Notes: A class method may constrain the class variables. The Haskell 98
  restriction rejected harmless programs; GHC2021 already lifted it.

`CUSKs`

- Category: Type Signatures.
- Hard-coded: Off.
- Editions: Haskell98, Haskell2010.
- Lines: +147 −592, net −445.
- Stability: Legacy.
- Notes: A complete user-supplied kind signature is never detected; a
  standalone kind signature fixes a kind. The heuristic was fragile and
  GHC2021 had it off.

`DataKinds`

- Category: Types.
- Hard-coded: On.
- Editions: GHC2024.
- Lines: +1712 −3140, net −1428.
- Stability: Stable.
- Notes: Every data type is promoted to a kind. Promotion is pervasive and
  GHC2024 enables it; the flag only rejected programs.

`DatatypeContexts`

- Category: Types.
- Hard-coded: Off.
- Editions: Haskell98, Haskell2010.
- Lines: +183 −1793, net −1610.
- Stability: Legacy; the user's guide marked it Deprecated.
- Notes: A data declaration never has a context. A long-deprecated
  misfeature: the context only burdened construction sites.

`DeepSubsumption`

- Category: Types.
- Hard-coded: Off.
- Editions: Haskell98, Haskell2010.
- Lines: +254 −861, net −607.
- Stability: Legacy.
- Notes: Subsumption is simple: no eta-expansion to match foralls under
  arrows. Simple subsumption is GHC's direction, and the eta-expansions
  changed semantics.

`DeriveDataTypeable`

- Category: Deriving Mechanism.
- Hard-coded: On.
- Editions: GHC2021, GHC2024.
- Lines: +84 −278, net −194.
- Stability: Stable.
- Notes: An instance of `Data` may always be derived. Harmless and common;
  GHC2021 enables it.

`DisambiguateRecordFields`

- Category: Syntax.
- Hard-coded: On.
- Editions: GHC2024; also implied by RecordWildCards and
  DuplicateRecordFields.
- Lines: +85 −432, net −347.
- Stability: Stable.
- Notes: A field in record construction or pattern matching is resolved
  through its data constructor, and a field in an update among the fields in
  scope alone. Accepts strictly more programs; GHC2024 enables it.

`DoRec`

- Category: Syntax.
- Hard-coded: N/A.
- Editions: none.
- Lines: +13 −11, net +2 (shared with RecordPuns; a regenerated test
  output).
- Stability: Deprecated.
- Notes: A deprecated alias of RecursiveDo.

`DuplicateRecordFields`

- Category: Syntax.
- Hard-coded: On.
- Editions: none.
- Lines: +404 −829, net −425.
- Stability: Uncategorized; the user's guide gives no stability status.
- Notes: Datatypes in one module may share field names and a module may
  export the shared fields together; a bare selector of a shared name is
  ambiguous. Record-heavy code already relies on it.

`ExplicitForAll`

- Category: Type Signatures.
- Hard-coded: On.
- Editions: GHC2021, GHC2024; also implied by RankNTypes,
  ScopedTypeVariables, LiberalTypeSynonyms, ExistentialQuantification and
  QuantifiedConstraints.
- Lines: +220 −452, net −232.
- Stability: Stable.
- Notes: `forall` is always a keyword in types. Nearly every type-level
  extension implied it; the only cost is that `forall` cannot name a type
  variable.

`ExplicitNamespaces`

- Category: Syntax.
- Hard-coded: On.
- Editions: GHC2024; also implied by TypeFamilies and TypeOperators.
- Lines: +439 −1244, net −805 (shared with StandaloneKindSignatures).
- Stability: Uncategorized; the user's guide lists it as included in
  GHC2024.
- Notes: The `type` and `data` namespace keywords are always accepted in
  import and export lists, fixity declarations, pragmas, expressions and
  patterns. GHC2024 enables it, and the keywords are unambiguous.

`HexFloatLiterals`

- Category: Literals.
- Hard-coded: On.
- Editions: GHC2021, GHC2024.
- Lines: +119 −429, net −310 (shared with BinaryLiterals, NumDecimals and
  NumericUnderscores).
- Stability: Stable.
- Notes: A floating-point literal may always be written in hexadecimal, as
  `0x1.8p3`. GHC2021 enables it; the only program it changes is one that
  meant `0x1.8` as the composition `0x1 . 8`.

`IncoherentInstances`

- Category: Classes & Instances.
- Hard-coded: Off.
- Editions: none.
- Lines: +148 −379, net −231 (shared with OverlappingInstances).
- Stability: Uncategorized; the user's guide marked it Deprecated.
- Notes: An instance is incoherent only by its own INCOHERENT pragma. The
  per-instance pragmas of GHC 7.10 made the module-wide switch obsolete.

`InstanceSigs`

- Category: Type Signatures.
- Hard-coded: On.
- Editions: GHC2021, GHC2024.
- Lines: +60 −163, net −103.
- Stability: Stable.
- Notes: An instance method may carry a type signature. It rejects nothing
  and documents the code; GHC2021 enables it.

`KindSignatures`

- Category: Type Signatures.
- Hard-coded: On.
- Editions: GHC2021, GHC2024; also implied by PolyKinds and TypeInType.
- Lines: +552 −891, net −339.
- Stability: Stable.
- Notes: Kind signatures may always be given. As ordinary as type
  annotations; GHC2021 enables them.

`MultilineStrings`

- Category: Literals.
- Hard-coded: On.
- Editions: none.
- Lines: +23 −732, net −709 (shared with QualifiedStrings).
- Stability: Uncategorized; newer than proposal 669, and the user's guide
  gives no status.
- Notes: A string literal may always span lines between `"""` delimiters,
  with the common indentation stripped. Before, `"""` lexed as `""` applied
  to another string, never meaningful code, so no program changes meaning.

`MultiParamTypeClasses`

- Category: Classes & Instances.
- Hard-coded: On.
- Editions: GHC2021, GHC2024; also implied by FunctionalDependencies.
- Lines: +566 −933, net −367 (shared with NullaryTypeClasses).
- Stability: Stable.
- Notes: A class may have any number of parameters. Standard practice;
  GHC2021 enables it.

`NondecreasingIndentation`

- Category: Syntax.
- Hard-coded: Off.
- Editions: Haskell98.
- Lines: +1281 −1443, net −162.
- Stability: Legacy.
- Notes: A nested `do` block must be indented further than its enclosing
  context, as the Haskell 2010 layout rule requires. A Haskell 98 leniency
  that GHC2021 had already dropped.

`NPlusKPatterns`

- Category: Syntax.
- Hard-coded: Off.
- Editions: Haskell98.
- Lines: +59 −666, net −607.
- Stability: Legacy.
- Notes: An `n+k` pattern is a parse error, as in Haskell 2010. Only the
  Haskell98 edition enabled it, and no corpus package writes one.

`NullaryTypeClasses`

- Category: Classes & Instances.
- Hard-coded: N/A.
- Editions: none.
- Lines: +566 −933, net −367 (shared with MultiParamTypeClasses).
- Stability: Deprecated.
- Notes: A no-op since GHC 7.10, when MultiParamTypeClasses came to cover
  nullary classes.

`NumDecimals`

- Category: Literals.
- Hard-coded: Off.
- Editions: none.
- Lines: +119 −429, net −310 (shared with BinaryLiterals, HexFloatLiterals
  and NumericUnderscores).
- Stability: Stable.
- Notes: A literal with a decimal point or an exponent is always fractional,
  so `1e6 :: Int` is a type error. In no edition, and whether `1.5e1` was
  integral depended on its value, which surprised readers.

`NumericUnderscores`

- Category: Literals.
- Hard-coded: On.
- Editions: GHC2021, GHC2024.
- Lines: +119 −429, net −310 (shared with BinaryLiterals, HexFloatLiterals
  and NumDecimals).
- Stability: Stable.
- Notes: Underscores may always separate the digits of a numeric literal,
  as `1_000_000`. GHC2021 enables it, and GHC already lexed `1_000` as one
  token and then rejected it, so no program changes meaning.

`OverlappingInstances`

- Category: Classes & Instances.
- Hard-coded: Off.
- Editions: none.
- Lines: +148 −379, net −231 (shared with IncoherentInstances).
- Stability: Deprecated.
- Notes: An instance overlaps only by its own OVERLAPPING, OVERLAPPABLE or
  OVERLAPS pragma; see IncoherentInstances.

`ParallelArrays`

- Category: Syntax.
- Hard-coded: N/A.
- Editions: none.
- Lines: +13 −85, net −72.
- Stability: Deprecated.
- Notes: The `[:` `:]` syntax left GHC with Data Parallel Haskell; the flag
  had become a spelling of ParallelListComp.

`ParallelListComp`

- Category: Syntax.
- Hard-coded: On.
- Editions: none; implied by MonadComprehensions.
- Lines: +40 −89, net −49.
- Stability: Stable.
- Notes: A list comprehension may have parallel branches. The syntax
  collides with nothing; turning it on only accepts more programs.

`PatternSignatures`

- Category: Type Signatures.
- Hard-coded: N/A.
- Editions: none.
- Lines: +5 −15, net −10.
- Stability: Uncategorized; the user's guide lists the flag as undocumented.
- Notes: A deprecated alias of ScopedTypeVariables.

`PolyKinds`

- Category: Types.
- Hard-coded: On.
- Editions: GHC2021, GHC2024.
- Lines: +2105 −3193, net −1088.
- Stability: Stable.
- Notes: Kinds are always generalised. The default since GHC2021; the
  monomorphic path was a second route through kind inference.

`PolymorphicComponents`

- Category: Types.
- Hard-coded: N/A.
- Editions: none.
- Lines: +52 −621, net −569 (shared with AlternativeLayoutRule and
  AlternativeLayoutRuleTransitional).
- Stability: Deprecated.
- Notes: A deprecated alias of RankNTypes.

`Rank2Types`

- Category: Types.
- Hard-coded: N/A.
- Editions: none.
- Lines: +17 −28, net −11.
- Stability: Deprecated.
- Notes: A deprecated alias of RankNTypes.

`QualifiedDo`

- Category: Syntax.
- Hard-coded: Off.
- Editions: none.
- Lines: +403 −4774, net −4371 (shared with ApplicativeDo).
- Stability: Stable.
- Notes: `M.do` is a parse error; a `do` block uses the `>>=`, `>>` and
  `fail` in scope, which `RebindableSyntax` can redirect. Template Haskell's
  `DoE` loses its module qualifier. No corpus package used it.

`QualifiedStrings`

- Category: Literals.
- Hard-coded: Off.
- Editions: none.
- Lines: +23 −732, net −709 (shared with MultilineStrings).
- Stability: Uncategorized; newer than proposal 669, and the user's guide
  gives no status.
- Notes: `M."text"` is no longer a literal; it parses as the constructor `M`
  composed with `"text"` by `.`, as before GHC 10. The sugar for
  `M.fromString "text"` cost a literal form through the whole front end.

`RankNTypes`

- Category: Types.
- Hard-coded: On.
- Editions: GHC2021, GHC2024; also implied by ImpredicativeTypes.
- Lines: +934 −1824, net −890.
- Stability: Stable.
- Notes: A type may have any rank. Higher-rank types are everywhere and
  GHC2021 enables them; the rank-1 restriction protected nothing.

`RecordPuns`

- Category: Syntax.
- Hard-coded: N/A.
- Editions: none.
- Lines: +13 −11, net +2 (shared with DoRec; a regenerated test output).
- Stability: Deprecated.
- Notes: A deprecated alias of NamedFieldPuns.

`RecursiveDo`

- Category: Syntax.
- Hard-coded: Off.
- Editions: none.
- Lines: +295 −2130, net −1835.
- Stability: Stable.
- Notes: There is no recursive do-notation: `mdo` is an ordinary identifier
  and `rec` a keyword of arrow notation alone; knots are tied with `mfix`.
  Hard-coding it on stole two keywords from every module.

`RelaxedPolyRec`

- Category: Types.
- Hard-coded: On.
- Editions: Haskell2010, GHC2021, GHC2024.
- Lines: +13 −57, net −44.
- Stability: Uncategorized; the user's guide gives no stability status, only
  its inclusion in Haskell2010, GHC2021 and GHC2024.
- Notes: Dependency analysis always ignores references to variables with
  signatures. Every edition since Haskell 2010 has it on.

`ScopedTypeVariables`

- Category: Type Signatures.
- Hard-coded: On.
- Editions: GHC2021, GHC2024.
- Lines: +894 −1668, net −774.
- Stability: Uncategorized; the user's guide lists it as included in GHC2021
  and GHC2024.
- Notes: Type variables are always lexically scoped: an outer `forall`, a
  class or instance head and a pattern signature bind them over the body.
  GHC2021 enables it, and the unscoped reading was a trap.

`StandaloneKindSignatures`

- Category: Type Signatures.
- Hard-coded: On.
- Editions: GHC2021, GHC2024; also implied by UnliftedDatatypes.
- Lines: +439 −1244, net −805 (shared with ExplicitNamespaces).
- Stability: Stable.
- Notes: A standalone kind signature may always be given. As ordinary as a
  type signature; GHC2021 enables it, and without CUSKs it is the only way
  to fix a type constructor's kind.

`StarIsType`

- Category: Syntax.
- Hard-coded: Off.
- Editions: Haskell98, Haskell2010, GHC2021, GHC2024.
- Lines: +7341 −5757, net +1584 (regenerated test output: kinds printed as
  `Type`, not `*`).
- Stability: Uncategorized; the user's guide lists it as included in all
  four editions.
- Notes: `*` is an ordinary type operator, never `Type`. It clashed with the
  operator and needed a lexer special case; proposal 143 planned to turn it
  off.

`TypeInType`

- Category: Types.
- Hard-coded: N/A.
- Editions: none.
- Lines: +41 −82, net −41.
- Stability: Deprecated.
- Notes: A deprecated spelling of PolyKinds, DataKinds and KindSignatures
  together, all now always on.

[669]: https://github.com/ghc-proposals/ghc-proposals/pull/669
