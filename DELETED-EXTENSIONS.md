# Deleted language extensions

**28 language extensions deleted.**

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
- **Notes**: what the hard-coded behaviour amounts to, and why it was fixed
  that way. The reasons are the author's best guesses at the motivation and
  may be revised.

`AlternativeLayoutRule`

- Category: Syntax.
- Hard-coded: N/A.
- Editions: none.
- Lines: +52 −621, net −569 (shared with AlternativeLayoutRuleTransitional
  and PolymorphicComponents).
- Stability: Deprecated.
- Notes: The alternative layout algorithm itself was deleted; GHC has one
  layout rule. An experimental reimplementation of the layout algorithm that
  was never finished or documented and that no code relies on; it only
  doubled the lexer's layout logic.

`AlternativeLayoutRuleTransitional`

- Category: Syntax.
- Hard-coded: N/A.
- Editions: none.
- Lines: +52 −621, net −569 (shared with AlternativeLayoutRule and
  PolymorphicComponents).
- Stability: Deprecated.
- Notes: As for AlternativeLayoutRule. The transitional variant of the same
  unfinished experiment.

`AutoDeriveTypeable`

- Category: Deriving Mechanism.
- Hard-coded: N/A.
- Editions: none.
- Lines: +30 −39, net −9.
- Stability: Uncategorized; the user's guide lists the flag as undocumented.
- Notes: Every type has had a `Typeable` instance since GHC 7.10; the flag
  did nothing beyond implying DeriveDataTypeable. A no-op for ten years,
  kept only so that old pragmas parsed.

`ConstrainedClassMethods`

- Category: Classes & Instances.
- Hard-coded: On.
- Editions: GHC2021, GHC2024; also implied by MultiParamTypeClasses.
- Lines: +36 −154, net −118.
- Stability: Stable.
- Notes: A class method may constrain the class type variables. The Haskell
  98 restriction rejected harmless programs and nothing was gained by
  enforcing it; GHC2021 already lifted it, and turning it on accepts
  strictly more programs.

`CUSKs`

- Category: Type Signatures.
- Hard-coded: Off.
- Editions: Haskell98, Haskell2010.
- Lines: +147 −592, net −445.
- Stability: Legacy.
- Notes: A complete user-supplied kind signature is never detected; a
  standalone kind signature is the way to fix a kind. The CUSK rule was a
  heuristic with subtle corner cases that StandaloneKindSignatures replaced
  with an explicit declaration; GHC2021 already turned it off, so off
  removes a fragile detection rule and its special cases in the kind
  checker.

`DataKinds`

- Category: Types.
- Hard-coded: On.
- Editions: GHC2024.
- Lines: +1712 −3140, net −1428.
- Stability: Stable.
- Notes: Every data type is promoted to a kind. Promotion is pervasive in
  current Haskell and GHC2024 enables it; the flag only rejected promoted
  constructors in kinds without changing the meaning of anything it
  accepted, and the checks for its absence were spread through the renamer
  and type checker.

`DatatypeContexts`

- Category: Types.
- Hard-coded: Off.
- Editions: Haskell98, Haskell2010.
- Lines: +183 −1793, net −1610.
- Stability: Legacy; the user's guide marked it Deprecated.
- Notes: A data type declaration never has a context. A widely acknowledged
  misfeature: the context only adds a requirement at construction sites and
  buys nothing; deprecated by GHC since 7.0 and off in GHC2021, so the
  choice follows the language's direction and lets the implementation go.

`DeepSubsumption`

- Category: Types.
- Hard-coded: Off.
- Editions: Haskell98, Haskell2010.
- Lines: +254 −861, net −607.
- Stability: Legacy.
- Notes: Subsumption is simple: GHC never eta-expands to match up foralls
  under arrows. Simple subsumption (GHC proposal 287) is the direction the
  language took, and the eta-expansions deep subsumption inserts change the
  semantics of programs; GHC2021 has it off, and not one corpus package
  needed it.

`DeriveDataTypeable`

- Category: Deriving Mechanism.
- Hard-coded: On.
- Editions: GHC2021, GHC2024.
- Lines: +84 −278, net −194.
- Stability: Stable.
- Notes: An instance of `Data` may always be derived. Deriving `Data` is
  harmless and common, and GHC2021 enables it; the flag gated nothing but a
  stock deriving.

`DoRec`

- Category: Syntax.
- Hard-coded: N/A.
- Editions: none.
- Lines: +13 −11, net +2 (shared with RecordPuns; a regenerated test
  output).
- Stability: Deprecated.
- Notes: The flag was a deprecated alias of RecursiveDo. A second spelling
  of an existing extension.

`ExplicitForAll`

- Category: Type Signatures.
- Hard-coded: On.
- Editions: GHC2021, GHC2024; also implied by RankNTypes,
  ScopedTypeVariables, LiberalTypeSynonyms, ExistentialQuantification and
  QuantifiedConstraints.
- Lines: +220 −452, net −232.
- Stability: Stable.
- Notes: `forall` is always a keyword in types. Almost every type-level
  extension implies it, so off was rarely observable; the only cost of on is
  that `forall` cannot name a type variable.

`IncoherentInstances`

- Category: Classes & Instances.
- Hard-coded: Off.
- Editions: none.
- Lines: +148 −379, net −231 (shared with OverlappingInstances).
- Stability: Uncategorized; the user's guide marked it Deprecated.
- Notes: An instance is incoherent only by its own INCOHERENT pragma; the
  module-wide default is gone. The per-instance pragmas of GHC 7.10 replaced
  the module-wide switch and make the intent visible at the instance; the
  switch had been deprecated ever since.

`InstanceSigs`

- Category: Type Signatures.
- Hard-coded: On.
- Editions: GHC2021, GHC2024.
- Lines: +60 −163, net −103.
- Stability: Stable.
- Notes: An instance method may carry a type signature. A signature in an
  instance rejects no program and documents the code; GHC2021 enables it.

`KindSignatures`

- Category: Type Signatures.
- Hard-coded: On.
- Editions: GHC2021, GHC2024; also implied by PolyKinds and TypeInType.
- Lines: +552 −891, net −339.
- Stability: Stable.
- Notes: Kind signatures may always be given. A kind annotation is as
  ordinary as a type annotation and GHC2021 enables it; on only accepts more
  programs.

`MultiParamTypeClasses`

- Category: Classes & Instances.
- Hard-coded: On.
- Editions: GHC2021, GHC2024; also implied by FunctionalDependencies.
- Lines: +566 −933, net −367 (shared with NullaryTypeClasses).
- Stability: Stable.
- Notes: A class may have any number of parameters. Multi-parameter classes
  are standard GHC practice and GHC2021 enables them; the Haskell 98
  restriction protected nothing.

`NullaryTypeClasses`

- Category: Classes & Instances.
- Hard-coded: N/A.
- Editions: none.
- Lines: +566 −933, net −367 (shared with MultiParamTypeClasses).
- Stability: Deprecated.
- Notes: The flag did nothing: MultiParamTypeClasses covered classes with no
  parameters since GHC 7.10. A no-op that survived only as a spelling.

`OverlappingInstances`

- Category: Classes & Instances.
- Hard-coded: Off.
- Editions: none.
- Lines: +148 −379, net −231 (shared with IncoherentInstances).
- Stability: Deprecated.
- Notes: An instance overlaps only by its own OVERLAPPING, OVERLAPPABLE or
  OVERLAPS pragma. As for IncoherentInstances: the per-instance pragmas
  replaced the module-wide switch in 7.10.

`ParallelArrays`

- Category: Syntax.
- Hard-coded: N/A.
- Editions: none.
- Lines: +13 −85, net −72.
- Stability: Deprecated.
- Notes: The `[:` `:]` syntax left GHC with Data Parallel Haskell; the flag
  had become a spelling of ParallelListComp. The feature it named no longer
  exists.

`ParallelListComp`

- Category: Syntax.
- Hard-coded: On.
- Editions: none; implied by MonadComprehensions.
- Lines: +40 −89, net −49.
- Stability: Stable.
- Notes: A list comprehension may have parallel branches, separated by `|`,
  which desugar to zips. The syntax collides with nothing else, so without
  the flag the parser accepted a parallel branch and the renamer rejected
  it; hard-coding it on accepts strictly more programs and removes that one
  check. MonadComprehensions implied the extension already.

`PatternSignatures`

- Category: Type Signatures.
- Hard-coded: N/A.
- Editions: none.
- Lines: +5 −15, net −10.
- Stability: Uncategorized; the user's guide lists the flag as undocumented.
- Notes: The flag was a deprecated alias of ScopedTypeVariables. A second
  spelling of an existing extension.

`PolyKinds`

- Category: Types.
- Hard-coded: On.
- Editions: GHC2021, GHC2024.
- Lines: +2105 −3193, net −1088.
- Stability: Stable.
- Notes: Kinds are always generalised. Kind polymorphism is the default
  since GHC2021, and the monomorphic alternative was a second code path
  through kind inference that only restricted generalisation; one path is
  simpler and matches what every modern program expects.

`PolymorphicComponents`

- Category: Types.
- Hard-coded: N/A.
- Editions: none.
- Lines: +52 −621, net −569 (shared with AlternativeLayoutRule and
  AlternativeLayoutRuleTransitional).
- Stability: Deprecated.
- Notes: The flag was a deprecated alias of RankNTypes. A second spelling of
  an existing extension.

`Rank2Types`

- Category: Types.
- Hard-coded: N/A.
- Editions: none.
- Lines: +17 −28, net −11.
- Stability: Deprecated.
- Notes: The flag was a deprecated alias of RankNTypes. A second spelling of
  an existing extension.

`RankNTypes`

- Category: Types.
- Hard-coded: On.
- Editions: GHC2021, GHC2024; also implied by ImpredicativeTypes.
- Lines: +934 −1824, net −890.
- Stability: Stable.
- Notes: A type may have any rank. Higher-rank types are everywhere in
  current Haskell, from lenses and `runST` to the Church encodings in
  `base`, and GHC2021 enables the extension; the Haskell 98 restriction to
  rank 1 rejected only programs that compile with the flag, and protected
  nothing once subsumption became simple. Hard-coding it on lets the
  validity checker drop the rank-1 machinery and the hints that pointed at
  the flag.

`RecordPuns`

- Category: Syntax.
- Hard-coded: N/A.
- Editions: none.
- Lines: +13 −11, net +2 (shared with DoRec; a regenerated test output).
- Stability: Deprecated.
- Notes: The flag was a deprecated alias of NamedFieldPuns. A second
  spelling of an existing extension.

`RelaxedPolyRec`

- Category: Types.
- Hard-coded: On.
- Editions: Haskell2010, GHC2021, GHC2024.
- Lines: +13 −57, net −44.
- Stability: Uncategorized; the user's guide gives no stability status, only
  its inclusion in Haskell2010, GHC2021 and GHC2024.
- Notes: The dependency analysis of a binding group always ignores
  references to variables with type signatures. Every edition since Haskell
  2010 has it on, and the Haskell 98 behaviour only rejects programs that
  type-check with it.

`StarIsType`

- Category: Syntax.
- Hard-coded: Off.
- Editions: Haskell98, Haskell2010, GHC2021, GHC2024.
- Lines: +7341 −5757, net +1584 (regenerated test output: kinds printed as
  `Type`, not `*`).
- Stability: Uncategorized; the user's guide lists it as included in all
  four editions.
- Notes: `*` is an ordinary type operator, never a spelling of `Type`. `*`
  as a kind clashes with `*` as a type operator and needs a special case in
  the lexer, and GHC proposal 143 planned to turn it off by default;
  `Data.Kind.Type` is unambiguous, and the corpus needed seventeen patches,
  which shows how much code still wrote `*` and that the migration is
  mechanical.

`TypeInType`

- Category: Types.
- Hard-coded: N/A.
- Editions: none.
- Lines: +41 −82, net −41.
- Stability: Deprecated.
- Notes: The flag was a deprecated spelling of PolyKinds, DataKinds and
  KindSignatures together, all three of which are now always on. Deprecated
  since GHC 8.6 in favour of naming the three extensions it implied.

[669]: https://github.com/ghc-proposals/ghc-proposals/pull/669
