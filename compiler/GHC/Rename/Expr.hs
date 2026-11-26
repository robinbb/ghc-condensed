{-# LANGUAGE CPP                 #-}
{-# LANGUAGE MonadComprehensions #-}
{-# LANGUAGE MultiWayIf          #-}
{-# LANGUAGE TypeFamilies        #-}
{-# LANGUAGE ViewPatterns        #-}

{-# OPTIONS_GHC -Wno-incomplete-record-updates #-}

{-
(c) The GRASP/AQUA Project, Glasgow University, 1992-1998

Renaming of expressions

Basically dependency analysis.

Handles @Match@, @GRHSs@, @HsExpr@, and @Qualifier@ datatypes.  In
general, all of these functions return a renamed thing, and a set of
free variables.
-}

module GHC.Rename.Expr (
        rnLExpr, rnExpr, rnStmts,
        AnnoBody, UnexpectedStatement(..)
   ) where

import GHC.Prelude hiding (head, init, last, tail)
import GHC.Hs

import GHC.Tc.Errors.Types
import GHC.Tc.Utils.Monad

import GHC.Rename.Bind ( rnLocalBindsAndThen, rnMatchGroup, rnGRHS )
import GHC.Rename.Env
import GHC.Rename.Fixity
import GHC.Rename.Utils
import GHC.Rename.Unbound ( reportUnboundName )
import GHC.Rename.Splice  ( rnTypedBracket, rnUntypedBracket, rnTypedSplice
                          , rnUntypedSpliceExpr, checkThLocalNameWithLift, checkThLocalNameNoLift )
import GHC.Rename.HsType
import GHC.Rename.Pat

import GHC.Driver.DynFlags
import GHC.Builtin.KnownKeys
import GHC.Builtin.KnownOccs
import GHC.Builtin.WiredIn.Types ( nilDataConName, oneDataConName )
import GHC.Builtin.WiredIn.Ids( rightSectionName, leftSectionName )


import GHC.Types.Basic (TypeOrKind (TypeLevel))
import GHC.Types.FieldLabel
import GHC.Types.Name
import GHC.Types.Name.Set
import GHC.Types.Name.Reader
import GHC.Types.Unique.Set
import GHC.Types.SourceText
import GHC.Types.SrcLoc

import GHC.Utils.Misc
import qualified GHC.Data.List.NonEmpty as NE
import GHC.Utils.Error
import GHC.Utils.Panic
import GHC.Utils.Outputable as Outputable

import GHC.Data.FastString
import GHC.Data.List.SetOps ( removeDupsOn )

import qualified GHC.LanguageExtensions as LangExt

import Control.Monad
import Data.List.NonEmpty ( NonEmpty(..), head, init, last, tail )

{- Note [Handling overloaded and rebindable constructs]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Nomenclature
-------------
* Expansion (`HsExpr GhcRn -> HsExpr GhcRn`): expand between renaming and
  typechecking, using the `XXExprGhcRn` constructor of `HsExpr`.
* Desugaring (`HsExpr GhcTc -> Core.Expr`): convert the typechecked `HsSyn` to Core.  This is done in GHC.HsToCore


For overloaded constructs (overloaded literals, lists, strings), and
rebindable constructs (e.g. if-then-else), our general plan is this,
using overloaded labels #foo as an example:

* In the RENAMER: transform
      HsOverLabel "foo"
      ==> XExpr (ExpandedThingRn (HsOverLabel #foo)
                                 (fromLabel `HsAppType` "foo"))
  We write this more compactly in concrete-syntax form like this
      #foo  ==>  fromLabel @"foo"

  Recall that in (ExpandedThingRn orig expanded), 'orig' is the original term
  the user wrote, and 'expanded' is the expanded or desugared version
  to be typechecked.

* In the TYPECHECKER: typecheck the expansion, in this case
      fromLabel @"foo"
  The typechecker (and desugarer) will never see HsOverLabel

In effect, the renamer does a bit of desugaring. Recall GHC.Hs.Expr
Note [Rebindable syntax and XXExprGhcRn], which describes the use of XXExprGhcRn.

RebindableSyntax:
  If RebindableSyntax is off we use the built-in 'fromLabel', defined in
     GHC.Builtin.KnownKeys.fromLabelClassOpName
  If RebindableSyntax if ON, we look up "fromLabel" in the environment
     to get whichever one is in scope.
This is accomplished by lookupSyntaxName, and it applies to all the
constructs below.

See also Note [Handling overloaded and rebindable patterns] in GHC.Rename.Pat
for the story with patterns.

Here are the expressions that we transform in this way. Some are uniform,
but several have a little bit of special treatment:

* HsIf (if-the-else)
     if b then e1 else e2  ==>  ifThenElse b e1 e2
  We do this /only/ if rebindable syntax is on, because the coverage
  checker looks for HsIf (see GHC.HsToCore.Ticks.addTickHsExpr)
  That means the typechecker and desugarer need to understand HsIf
  for the non-rebindable-syntax case.

* OverLabel (overloaded labels, #lbl)
     #lbl  ==>  fromLabel @"lbl"
  As ever, we use lookupSyntaxName to look up 'fromLabel'
  See Note [Overloaded labels] below

* ExplicitList (explicit lists [a,b,c])
  When (and only when) OverloadedLists is on
     [e1,e2]  ==>  fromListN 2 [e1,e2]
  NB: the type checker and desugarer still see ExplicitList,
      but to them it always means the built-in lists.

* SectionL and SectionR (left and right sections)
     (`op` e) ==> rightSection op e
     (e `op`) ==> leftSection  (op e)
  where `leftSection` and `rightSection` are representation-polymorphic
  wired-in Ids. See Note [Left and right sections]

* To understand why expansions for `OpApp` is done in `GHC.Tc.Gen.Head.splitHsApps`
  see Note [Doing XXExprGhcRn in the Renamer vs Typechecker] below.

* RecordUpd: we desugar record updates into case expressions,
  in GHC.Tc.Gen.Expr.tcExpr.

  Example:

    data T p q = T1 { x :: Int, y :: Bool, z :: Char }
               | T2 { v :: Char }
               | T3 { x :: Int }
               | T4 { p :: Float, y :: Bool, x :: Int }
               | T5

    e { x=e1, y=e2 }
      ===>
    let { x' = e1; y' = e2 } in
    case e of
       T1 _ _ z -> T1 x' y' z
       T4 p _ _ -> T4 p y' x'

  See Note [Record Updates] in GHC.Tc.Gen.Expr for more details.

  To understand Why is this done in the typechecker, and not in the renamer
  see Note [Doing XXExprGhcRn in the Renamer vs Typechecker]

* HsDo: We expand `HsDo` statements in `Ghc.Tc.Gen.Do`.

    - For example, a user written code:

                  do { x <- e1 ; g x ; return (f x) }

      is expanded to:

                   (>>=) e1
                         (\x -> ((>>) (g x)
                                      (return (f x))))

     See Note [Expanding HsDo with XXExprGhcRn] in `Ghc.Tc.Gen.Do` for more details.
     To understand why is this done in the typechecker and not in the renamer.
     See Note [Doing XXExprGhcRn in the Renamer vs Typechecker]

Note [Overloaded labels]
~~~~~~~~~~~~~~~~~~~~~~~~
For overloaded labels, note that we /only/ apply `fromLabel` to the
Symbol argument, so the resulting expression has type
    fromLabel @"foo" :: forall a. IsLabel "foo" a => a
Now ordinary Visible Type Application can be used to instantiate the 'a':
the user may have written (#foo @Int).

Notice that this all works fine in a kind-polymorphic setting (#19154).
Suppose we have
    fromLabel :: forall {k1} {k2} (a:k1). blah

Then we want to instantiate those inferred quantifiers k1,k2, before
type-applying to "foo", so we get
    fromLabel @Symbol @blah @"foo" ...

And those inferred kind quantifiers will indeed be instantiated when we
typecheck the renamed-syntax call (fromLabel @"foo").

Note [Doing XXExprGhcRn in the Renamer vs Typechecker]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
We expand some `HsExpr GhcRn` code at various places, usually, on the fly,
depending on when it is more convenient. It may be beneficial to have a
separate `HsExpr GhcRn -> HsExpr GhcRn` pass that does this expansion uniformly
in the future when we have enough cases to cater for. For the time being,
this note documents which language feature is expanded at which phase,
and the reasons for doing so.

  ** `HsIf` Expansions
  --------------------
  `HsIf` expansions are expanded in the Renamer becuase it is more convinent
  to do so there and then not worry about it in the later stage.
  `-XRebindableSyntax` is used to decide whether we use the `HsIf` or user defined if


  ** `OpApp` Expansions
  ---------------------
  The typechecker turns `OpApp` into a use of `XXExprGhcRn`
  on the fly, in `GHC.Tc.Gen.Head.splitHsApps`.
  The language extension `RebindableSyntax` does not affect this behaviour.

  It's a bit painful to transform `OpApp e1 op e2` to a `XXExprGhcRn`
  form, because the renamer does precedence rearrangement after name
  resolution. So the renamer leaves an `OpApp` as an `OpApp`.

  ** Record Update Syntax `RecordUpd` Expansions
  ----------------------------------------------
  This is done in the typechecker on the fly (`GHC.Tc.Expr.tcExpr`), and not the renamer, for two reasons:

    - (Until we implement GHC proposal #366)
      We need to know the type of the record to disambiguate its fields.

    - We use the type signature of the data constructor to provide `IdSigs`
      to the let-bound variables (x', y' in the example of
      Note [Handling overloaded and rebindable constructs] above).
      This is needed to accept programs such as

          data R b = MkR { f :: (forall a. a -> a) -> (Int,b), c :: Int }
          foo r = r { f = \ k -> (k 3, k 'x') }

      in which an updated field has a higher-rank type.
      See Wrinkle [Using IdSig] in Note [Record Updates] in GHC.Tc.Gen.Expr.

  ** `HsDo` Statement Expansions
  -----------------------------------
  The expansion for do block statements is done on the fly right before typechecking in `GHC.Tc.Gen.Expr`
  using `GHC.Tc.Gen.Do.expandDoStmts`. There are 2 main reasons:

  -  During the renaming phase, we may not have all the constructor details `HsConDetails` populated in the
     data structure. This would result in an inaccurate irrefutability analysis causing
     the continuation lambda body to be wrapped with `fail` alternatives when not needed.
     See Part 1. of Note [Expanding HsDo with XXExprGhcRn] (test pattern-fails.hs)

  -  If the expansion is done on the fly during renaming, expressions that
     have explicit type applications using (-XTypeApplciations) will not work (cf. Let statements expansion)
     as the name freshening happens from the root of the AST to the leaves,
     but the expansion happens in the opposite direction (from leaves to the root),
     causing the renamer to miss the scoped type variables.
-}

{-
************************************************************************
*                                                                      *
\subsubsection{Expressions}
*                                                                      *
************************************************************************
-}

rnExprs :: [LHsExpr GhcPs] -> RnM ([LHsExpr GhcRn], FreeNames)
rnExprs ls = rnExprs' ls emptyUniqSet
 where
  rnExprs' [] acc = return ([], acc)
  rnExprs' (expr:exprs) acc =
   do { (expr', fvExpr) <- rnLExpr expr
        -- Now we do a "seq" on the free vars because typically it's small
        -- or empty, especially in very long lists of constants
      ; let  acc' = acc `plusFN` fvExpr
      ; (exprs', fvExprs) <- acc' `seq` rnExprs' exprs acc'
      ; return (expr':exprs', fvExprs) }

-- Variables. We look up the variable and return the resulting name.

rnLExpr :: LHsExpr GhcPs -> RnM (LHsExpr GhcRn, FreeNames)
rnLExpr = wrapLocFstMA rnExpr

rnExpr :: HsExpr GhcPs -> RnM (HsExpr GhcRn, FreeNames)

rnUnboundVar :: SrcSpanAnnN -> RdrName -> RnM (HsExpr GhcRn, FreeNames)
rnUnboundVar l v = do
  deferOutofScopeVariables <- goptM Opt_DeferOutOfScopeVariables
  -- See Note [Reporting unbound names] for difference between qualified and unqualified names.
  unless (isUnqual v || deferOutofScopeVariables) $
    void $ reportUnboundName WL_Term v
  return (HsHole (HoleVar (L l v)), emptyFNs)

rnExpr (HsVar _ (L l v))
  = do { dflags <- getDynFlags
       ; mb_gre <- lookupExprOccRn v
       ; case mb_gre of {
           Nothing -> rnUnboundVar l v ;
           Just gre ->
    do { let nm   = greName gre
             info = greInfo gre
       ; if | IAmRecField fld_info <- info
            -- Since GHC 9.4, such occurrences of record fields must be
            -- unambiguous. For ambiguous occurrences, we arbitrarily pick one
            -- matching GRE and add a name clash error
            -- (see lookupGlobalOccRn_overloaded, called by lookupExprOccRn).
            -> do { let sel_name = flSelector $ recFieldLabel fld_info
                  ; checkThLocalNameNoLift (L l $ WithUserRdr v gre)
                  ; return (XExpr (HsRecSelRn (FieldOcc v  (L l sel_name))), unitFN sel_name)
                  }
            | nm == nilDataConName
              -- Treat [] as an ExplicitList, so that
              -- OverloadedLists works correctly
              -- Note [Empty lists] in GHC.Hs.Expr
            , xopt LangExt.OverloadedLists dflags
            -> rnExpr (ExplicitList noAnn [])

            | otherwise
            -> do { res_expr <- checkThLocalNameWithLift (L (l2l l) (WithUserRdr v gre))
                  ; return (res_expr, unitFN nm) }
        }}}


rnExpr (HsIPVar x v)
  = return (HsIPVar x v, emptyFNs)

rnExpr (HsHole h)
  = return (HsHole h, emptyFNs)

-- HsOverLabel: see Note [Handling overloaded and rebindable constructs]
rnExpr (HsOverLabel src v)
  = do { (from_label, fvs) <- lookupSyntaxName fromLabelClassOpOcc
       ; return ( mkExpandedExpr (HsOverLabel src v) $
                  HsAppType noExtField (genLHsVar from_label) hs_ty_arg
                , fvs ) }
  where
    hs_ty_arg = mkEmptyWildCardBndrs $ wrapGenSpan $
                HsTyLit noExtField (HsString NoSourceText v)

rnExpr (HsLit x lit) | HsString src s <- lit
  = do { opt_OverloadedStrings <- xoptM LangExt.OverloadedStrings
       ; if opt_OverloadedStrings then
            rnExpr (HsOverLit x (mkHsIsString src s))
         else do {
            ; rnLit lit
            ; return (HsLit x (convertLit lit), emptyFNs) } }

rnExpr (HsLit x lit)
  = do { rnLit lit
       ; return (HsLit x (convertLit lit), emptyFNs) }

rnExpr (HsOverLit x lit)
  = do { ((lit', mb_neg), fvs) <- rnOverLit lit -- See Note [Negative zero]
       ; case mb_neg of
              Nothing -> return (HsOverLit x lit', fvs)
              Just neg ->
                 return (HsApp noExtField (noLocA neg) (noLocA (HsOverLit x lit'))
                        , fvs ) }

rnExpr (HsApp x fun arg)
  = do { (fun',fvFun) <- rnLExpr fun
       ; (arg',fvArg) <- rnLExpr arg
       ; return (HsApp x fun' arg', fvFun `plusFN` fvArg) }

rnExpr (HsAppType _ fun arg)
  = do { type_app <- xoptM LangExt.TypeApplications
       ; unless type_app $ addErr $ typeAppErr TypeLevel $ hswc_body arg
       ; (fun',fvFun) <- rnLExpr fun
       ; (arg',fvArg) <- rnHsWcType HsTypeCtx arg
       ; return (HsAppType noExtField fun' arg', fvFun `plusFN` fvArg) }

rnExpr (OpApp _ e1 op e2)
  = do  { (e1', fv_e1) <- rnLExpr e1
        ; (e2', fv_e2) <- rnLExpr e2
        ; (op', fv_op) <- rnLExpr op

        -- Deal with fixity
        -- When renaming code synthesised from "deriving" declarations
        -- we used to avoid fixity stuff, but we can't easily tell any
        -- more, so I've removed the test.  Adding HsPars in GHC.Tc.Deriv.Generate
        -- should prevent bad things happening.
        ; fixity <- lookupExprFixityRn op'
        ; lexical_negation <- xoptM LangExt.LexicalNegation
        ; let negation_handling | lexical_negation = KeepNegationIntact
                                | otherwise = ReassociateNegation
        ; final_e <- mkOpAppRn negation_handling e1' op' fixity e2'
        ; return (final_e, fv_e1 `plusFN` fv_op `plusFN` fv_e2) }

rnExpr (NegApp _ e _)
  = do { (e', fv_e)         <- rnLExpr e
       ; (neg_name, fv_neg) <- lookupSyntax negateClassOpOcc
       ; final_e            <- mkNegAppRn e' neg_name
       ; return (final_e, fv_e `plusFN` fv_neg) }

------------------------------------------
-- Record dot syntax

rnExpr (HsGetField _ e f)
 = do { (getField, fv_getField) <- lookupSyntaxName getFieldClassOpOcc
      ; (e, fv_e) <- rnLExpr e
      ; let f' = rnDotFieldOcc <$> f
      ; return ( mkExpandedExpr
                   (HsGetField noExtField e f')
                   (mkGetField getField e (fmap (unLoc . dfoLabel) f'))
               , fv_e `plusFN` fv_getField ) }

rnExpr (HsProjection _ fs)
  = do { (getField, fv_getField) <- lookupSyntaxName getFieldClassOpOcc
       ; circ <- rnLookupKnownOccName composeIdOcc
       ; let fs' = NE.map rnDotFieldOcc fs
       ; return ( mkExpandedExpr
                    (HsProjection noExtField fs')
                    (mkProjection getField circ $ NE.map (unLoc . dfoLabel) fs')
                , unitFN circ `plusFN` fv_getField) }

------------------------------------------
-- Template Haskell extensions
rnExpr e@(HsTypedBracket _ br_body)   = rnTypedBracket e br_body
rnExpr e@(HsUntypedBracket _ br_body) = rnUntypedBracket e br_body

rnExpr (HsTypedSplice   _ splice) = rnTypedSplice splice
rnExpr (HsUntypedSplice _ splice) = rnUntypedSpliceExpr splice

---------------------------------------------
--      Sections
-- See Note [Parsing sections] in GHC.Parser
rnExpr (HsPar _ (L loc (section@(SectionL {}))))
  = do  { (section', fvs) <- rnSection section
        ; return (HsPar noExtField (L loc section'), fvs) }

rnExpr (HsPar _ (L loc (section@(SectionR {}))))
  = do  { (section', fvs) <- rnSection section
        ; return (HsPar noExtField (L loc section'), fvs) }

rnExpr (HsPar _ e)
  = do  { (e', fvs_e) <- rnLExpr e
        ; return (HsPar noExtField e', fvs_e) }

rnExpr expr@(SectionL {})
  = do  { addErr (sectionErr expr); rnSection expr }
rnExpr expr@(SectionR {})
  = do  { addErr (sectionErr expr); rnSection expr }

---------------------------------------------
rnExpr (HsPragE x prag expr)
  = do { (expr', fvs_expr) <- rnLExpr expr
       ; return (HsPragE x (rn_prag prag) expr', fvs_expr) }
  where
    rn_prag :: HsPragE GhcPs -> HsPragE GhcRn
    rn_prag (HsPragSCC x ann) = HsPragSCC x $ rnStringLit ann

rnExpr (HsLam x lam_variant matches)
  = do { (matches', fvs_ms) <- rnMatchGroup (LamAlt lam_variant) rnLExpr matches
       ; return (HsLam x lam_variant matches', fvs_ms) }

rnExpr (HsCase _ expr matches)
  = do { (new_expr, e_fvs) <- rnLExpr expr
       ; (new_matches, ms_fvs) <- rnMatchGroup CaseAlt rnLExpr matches
       ; return (HsCase CaseAlt new_expr new_matches, e_fvs `plusFN` ms_fvs) }

rnExpr (HsLet _ binds expr)
  = rnLocalBindsAndThen binds $ \binds' _ -> do
      { (expr',fvExpr) <- rnLExpr expr
      ; return (HsLet noExtField binds' expr', fvExpr) }

rnExpr (HsDo _ do_or_lc (L l stmts))
 = do { ((stmts', _), fvs) <-
          rnStmts (HsDoStmt do_or_lc) rnExpr stmts
            (\ _ -> return ((), emptyFNs))
      ; return ( HsDo noExtField do_or_lc (L l stmts'), fvs ) }

-- ExplicitList: see Note [Handling overloaded and rebindable constructs]
rnExpr (ExplicitList _ exps)
  = do  { (exps', fvs) <- rnExprs exps
        ; opt_OverloadedLists <- xoptM LangExt.OverloadedLists
        ; if not opt_OverloadedLists
          then return  (ExplicitList noExtField exps', fvs)
          else
    do { (from_list_n_name, fvs') <- lookupSyntaxName fromListNClassOpOcc
       ; loc <- getSrcSpanM -- See Note [Source locations for implicit function calls]
       ; let rn_list  = ExplicitList noExtField exps'
             lit_n    = mkIntegralLit (length exps)
             hs_lit   = genHsIntegralLit lit_n
             exp_list = genHsApps' (wrapGenSpan' loc from_list_n_name) [hs_lit, wrapGenSpan rn_list]
       ; return ( mkExpandedExpr rn_list exp_list
                , fvs `plusFN` fvs') } }

rnExpr (ExplicitTuple _ tup_args boxity)
  = do { checkTupleSection tup_args
       ; (tup_args', fvs) <- mapAndUnzipM rnTupArg tup_args
       ; return (ExplicitTuple noExtField tup_args' boxity, plusFNs fvs) }
  where
    rnTupArg (Present x e) = do { (e',fvs) <- rnLExpr e
                                ; return (Present x e', fvs) }
    rnTupArg (Missing _) = return (Missing noExtField, emptyFNs)

rnExpr (ExplicitSum _ alt arity expr)
  = do { (expr', fvs) <- rnLExpr expr
       ; return (ExplicitSum noExtField alt arity expr', fvs) }

rnExpr (RecordCon { rcon_con = con_rdr
                  , rcon_flds = rec_binds@(HsRecFields { rec_dotdot = dd }) })
  = do { L con_loc con_name <- lookupLocatedOccRnConstr con_rdr
       ; let qcon = WithUserRdr (unLoc con_rdr) con_name
       ; (flds, fvs)   <- rnHsRecFields (HsRecFieldCon qcon) mk_hs_var rec_binds
       ; (flds', fvss) <- mapAndUnzipM rn_field flds
       ; let rec_binds' = HsRecFields { rec_ext = noAnn, rec_flds = flds', rec_dotdot = dd }
       ; return (RecordCon { rcon_ext = noExtField
                           , rcon_con = L con_loc qcon
                           , rcon_flds = rec_binds' }
                , fvs `plusFN` plusFNs fvss `addOneFN` con_name) }
  where
    mk_hs_var l n = mkHsVarWithUserRdr (unLoc con_rdr) (L (noAnnSrcSpan l) n)
    rn_field (L l fld) = do { (arg', fvs) <- rnLExpr (hfbRHS fld)
                            ; return (L l (fld { hfbRHS = arg' }), fvs) }

rnExpr (RecordUpd { rupd_expr = L l expr, rupd_flds = rbinds })
  = setSrcSpanA l $
    case rbinds of

      -- 'OverloadedRecordUpdate' is not in effect. Regular record update.
      RegularRecUpdFields { recUpdFields = flds } ->
        do  { (e, fv_e) <- rnExpr expr
            ; (parents, flds, fv_flds) <- rnHsRecUpdFields flds
            ; let upd_flds =
                    RegularRecUpdFields
                    { xRecUpdFields = parents
                    , recUpdFields  = flds }
            ; return ( RecordUpd noExtField (L l e) upd_flds
                     , fv_e `plusFN` fv_flds ) }

      -- 'OverloadedRecordUpdate' is in effect. Record dot update desugaring.
      OverloadedRecUpdFields { olRecUpdFields = flds } ->
        do { unlessXOptM LangExt.RebindableSyntax $
               addErr TcRnNoRebindableSyntaxRecordDot
           ; let punnedFields = [fld | (L _ fld) <- flds, hfbPun fld]
           ; punsEnabled <- xoptM LangExt.NamedFieldPuns
           ; unless (null punnedFields || punsEnabled) $
               addErr TcRnNoFieldPunsRecordDot
           ; (getField, fv_getField) <- lookupSyntaxName getFieldClassOpOcc
           ; (setField, fv_setField) <- lookupSyntaxName setFieldClassOpOcc
           ; (e, fv_e) <- rnExpr expr
           ; (us, fv_us) <- rnHsUpdProjs flds
            ; let upd_flds = OverloadedRecUpdFields
                            { xOLRecUpdFields = noExtField
                            , olRecUpdFields  = us }
            ; return ( mkExpandedExpr
                         (RecordUpd noExtField (L l e) upd_flds)
                         (mkRecordDotUpd getField setField (L l e) us)
                        , plusFNs [fv_getField, fv_setField, fv_e, fv_us] ) }


rnExpr (ExprWithTySig _ expr pty)
  = do  { (pty', fvTy)    <- rnHsSigWcType ExprWithTySigCtx pty
        ; (expr', fvExpr) <- bindSigTyVarsFV (hsWcScopedTvs pty') $
                             rnLExpr expr
        ; return (ExprWithTySig noExtField expr' pty', fvExpr `plusFN` fvTy) }

-- HsIf: see Note [Handling overloaded and rebindable constructs]
-- Because of the coverage checker it is most convenient /not/ to
-- expand HsIf; unless we are in rebindable syntax.
rnExpr (HsIf _ p b1 b2) = rnHsIf p b1 b2

rnExpr (HsMultiIf _ alts)
  = do { (alts', fvs) <- mapFvRn (rnGRHS IfAlt rnLExpr) alts
       ; return (HsMultiIf noExtField alts', fvs) }

rnExpr (ArithSeq _ _ seq)
  = do { opt_OverloadedLists <- xoptM LangExt.OverloadedLists
       ; (new_seq, fvs) <- rnArithSeq seq
       ; if opt_OverloadedLists
           then do {
            ; (from_list_name, fvs') <- lookupSyntax fromListClassOpOcc
            ; return (ArithSeq noExtField (Just from_list_name) new_seq
                     , fvs `plusFN` fvs') }
           else
            return (ArithSeq noExtField Nothing new_seq, fvs) }

rnExpr (HsEmbTy _ ty)
  = do { (ty', fvs) <- rnHsWcType HsTypeCtx ty
       ; return (HsEmbTy noExtField ty', fvs) }

rnExpr (HsQual x (L l (HsContext an ctxt)) ty)
  = do { (ctxt', fvs_ctxt) <- mapAndUnzipM rnLExpr ctxt
       ; (ty', fvs_ty) <- rnLExpr ty
       ; checkTypeSyntaxExtension ContextArrowSyntax
       ; return (HsQual x (L l (HsContext an ctxt')) ty', plusFNs fvs_ctxt `plusFN` fvs_ty) }

rnExpr (HsForAll _ tele expr)
  = bindHsForAllTelescope HsTypeCtx tele $ \tele' ->
    do { (expr', fvs) <- rnLExpr expr
       ; checkTypeSyntaxExtension ForallTelescopeSyntax
       ; return (HsForAll noExtField tele' expr', fvs) }

rnExpr (HsFunArr _ mult arg res)
  = do { (arg', fvs1) <- rnLExpr arg
       ; (mult', fvs2) <- rnHsModifiedFunArrWith rnModifierExpr mult
       ; (res', fvs3) <- rnLExpr res
       ; checkTypeSyntaxExtension FunctionArrowSyntax
       ; return (HsFunArr noExtField mult' arg' res', plusFNs [fvs1, fvs2, fvs3]) }
  where
    rnModifierExpr =
      rnModifierWith (\ex -> if isLiteral1 ex then Just oneType else Nothing)
                     rnLExpr
    isLiteral1 ex = case ex of
      (L _ (HsOverLit _ (OverLit _ (HsIntegral (IL (SourceText (unpackFS -> "1")) _ 1))))) -> True
      _ -> False
    oneType = noLocA $ HsVar noExtField $ noLocA $ noUserRdr oneDataConName

{-
************************************************************************
*                                                                      *
        Static values
*                                                                      *
************************************************************************

For the static form we check that it is not used in splices.
We also collect the free variables of the term which come from
this module. See Note [Grand plan for static forms] in GHC.Iface.Tidy.StaticPtrTable.
-}

rnExpr e@(HsStatic _ expr)
  = do { -- Check for -XStaticPointers
         -- Normally, you wouldn't be able to construct a static expression without
         -- first enabling -XStaticPointers in the first place, since that extension
         -- is what makes the parser treat `static` as a keyword. But this is not a
         -- sufficient safeguard, as one can construct static expressions by another
         -- mechanism: Template Haskell (see #14204). To ensure that GHC is
         -- absolutely prepared to cope with static forms, we check for
         -- -XStaticPointers here as well.
       ; unlessXOptM LangExt.StaticPointers $
         addErr $ TcRnIllegalStaticExpression e

       -- Check Template Haskell level
       ; level <- getThLevel
       ; case level of
           Splice _ _ -> addErr $ TcRnTHError $ IllegalStaticFormInSplice e
           _        -> return ()

       -- Rename the payload
       ; (expr',fvs) <- rnLExpr expr

       ; return (HsStatic fvs expr', fvs) }

{-
************************************************************************
*                                                                      *
        Type syntax
*                                                                      *
********************************************************************* -}

checkTypeSyntaxExtension :: TypeSyntax -> RnM ()
checkTypeSyntaxExtension syntax =
  unlessXOptM LangExt.RequiredTypeArguments $
  addErr (TcRnUnexpectedTypeSyntaxInTerms syntax)

{-
************************************************************************
*                                                                      *
        Operator sections
*                                                                      *
********************************************************************* -}


rnSection :: HsExpr GhcPs -> RnM (HsExpr GhcRn, FreeNames)
-- See Note [Parsing sections] in GHC.Parser
-- Also see Note [Handling overloaded and rebindable constructs]

rnSection section@(SectionR x op expr)
  -- See Note [Left and right sections]
  = do  { (op', fvs_op)     <- rnLExpr op
        ; (expr', fvs_expr) <- rnLExpr expr
        ; checkSectionPrec InfixR section op' expr'
        ; let rn_section = SectionR x op' expr'
              ds_section = genHsApps rightSectionName [op',expr']
        ; return ( mkExpandedExpr rn_section ds_section
                 , fvs_op `plusFN` fvs_expr) }

rnSection section@(SectionL x expr op)
  -- See Note [Left and right sections]
  = do  { (expr', fvs_expr) <- rnLExpr expr
        ; (op', fvs_op)     <- rnLExpr op
        ; checkSectionPrec InfixL section op' expr'
        ; postfix_ops <- xoptM LangExt.PostfixOperators
                        -- Note [Left and right sections]
        ; let rn_section = SectionL x expr' op'
              ds_section
                | postfix_ops = HsApp noExtField op' expr'
                | otherwise   = genHsApps leftSectionName
                                   [wrapGenSpan $ HsApp noExtField op' expr']
        ; return ( mkExpandedExpr rn_section ds_section
                 , fvs_op `plusFN` fvs_expr) }

rnSection other = pprPanic "rnSection" (ppr other)

{- Note [Left and right sections]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Dealing with left sections (x *) and right sections (* x) is
surprisingly fiddly.  We expand like this
     (`op` e) ==> rightSection op e
     (e `op`) ==> leftSection  (op e)

Using an auxiliary function in this way avoids the awkwardness of
generating a lambda, esp if `e` is a redex, so we *don't* want
to generate `(\x -> op x e)`. See Historical
Note [Desugaring operator sections]

Here are their definitions:
   leftSection :: forall r1 r2 n (a::TYPE r1) (b::TYPE r2).
                  (a %n-> b) -> a %n-> b
   leftSection f x = f x

   rightSection :: forall r1 r2 r3 n1 n2 (a::TYPE r1) (b::TYPE r2) (c::TYPE r3).
                   (a %n1 -> b %n2-> c) -> b %n2-> a %n1-> c
   rightSection f y x = f x y

Note the wrinkles:

* We do /not/ use lookupSyntaxName, which would make left and right
  section fall under RebindableSyntax.  Reason: it would be a user-
  facing change, and there are some tricky design choices (#19354).
  Plus, infix operator applications would be trickier to make
  rebindable, so it'd be inconsistent to do so for sections.

  TL;DR: we still use the renamer-expansion mechanism for operator
  sections, but only to eliminate special-purpose code paths in the
  renamer and desugarer.

* leftSection and rightSection must be representation-polymorphic, to allow
  (+# 4#) and (4# +#) to work. See
  Note [Wired-in Ids for rebindable syntax] in GHC.Types.Id.Make.

* leftSection and rightSection must be multiplicity-polymorphic.
  (Test linear/should_compile/OldList showed this up.)

* Because they are representation-polymorphic, we have to define them
  as wired-in Ids, with compulsory inlining.  See
  GHC.Types.Id.Make.leftSectionId, rightSectionId.

* leftSection is just ($) really; but unlike ($) it is
  representation-polymorphic in the result type, so we can write
  `(x +#)`, say.

* The type of leftSection must have an arrow in its first argument,
  because (x `ord`) should be rejected, because ord does not take two
  arguments

* It's important that we define leftSection in an eta-expanded way,
  (i.e. not leftSection f = f), so that
      (True `undefined`) `seq` ()
      = (leftSection (undefined True) `seq` ())
  evaluates to () and not undefined

* If PostfixOperators is ON, then we expand a left section like this:
      (e `op`)  ==>   op e
  with no auxiliary function at all.  Simple!

* leftSection and rightSection switch on ImpredicativeTypes locally,
  during Quick Look; see GHC.Tc.Gen.App.wantQuickLook. Consider:
     type Setter st t a b = forall f. Identical f => blah
     (.~) :: Setter s t a b -> b -> s -> t
     clear :: Setter a a' b (Maybe b') -> a -> a'
     clear = (.~ Nothing)
   The expansion look like (rightSection (.~) Nothing).  So we must
   instantiate `rightSection` first type argument to a polytype!
   Hence the special magic in App.wantQuickLook.

Historical Note [Desugaring operator sections]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
This Note explains some historical trickiness in desugaring left and
right sections.  That trickiness has completely disappeared now that
we desugar to calls to 'leftSection` and `rightSection`, but I'm
leaving it here to remind us how nice the new story is.

Desugaring left sections with -XPostfixOperators is straightforward: convert
(expr `op`) to (op expr).

Without -XPostfixOperators it's a bit more tricky. At first it looks as if we
can convert

    (expr `op`)

naively to

    \x -> op expr x

But no!  expr might be a redex, and we can lose laziness badly this
way.  Consider

    map (expr `op`) xs

for example. If expr were a redex then eta-expanding naively would
result in multiple evaluations where the user might only have expected one.

So we convert instead to

    let y = expr in \x -> op y x

Also, note that we must do this for both right and (perhaps surprisingly) left
sections. Why are left sections necessary? Consider the program (found in #18151),

    seq (True `undefined`) ()

according to the Haskell Report this should reduce to () (as it specifies
desugaring via eta expansion). However, if we fail to eta expand we will rather
bottom. Consequently, we must eta expand even in the case of a left section.

If `expr` is actually just a variable, say, then the simplifier
will inline `y`, eliminating the redundant `let`.

Note that this works even in the case that `expr` is unlifted. In this case
bindNonRec will automatically do the right thing, giving us:

    case expr of y -> (\x -> op y x)

See #18151.

Note [Reporting unbound names]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Faced with an out-of-scope `RdrName` there are two courses of action
A. Report an error immediately (and return a `HsHole (HoleVar ...)`). This will halt GHC after the renamer is complete
B. Return a `HsHole (HoleVar ...)` without reporting an error.  That will allow the typechecker to run, which in turn
   can give a better error message, notably giving the type of the variable via the "typed holes" mechanism.

When `-fdefer-out-of-scope-variables` is on we follow plan B.

When it is not, we follow plan B for unqualified names, and plan A for qualified names.

If a name is qualified, and out of scope, then by default an error will be raised
because the user was already more precise. They specified a specific qualification
and either
  * The qualification didn't exist, so that precision was wrong.
  * Or the qualification existed and the thing we were looking for wasn't where
    the qualification said it would be.

However we can still defer this error completely, and we do defer it if
`-fdefer-out-of-scope-variables` is enabled.

-}

{-
************************************************************************
*                                                                      *
        Field Labels
*                                                                      *
************************************************************************
-}

rnDotFieldOcc :: DotFieldOcc GhcPs ->  DotFieldOcc GhcRn
rnDotFieldOcc (DotFieldOcc x label) = DotFieldOcc x label

rnFieldLabelStrings :: FieldLabelStrings GhcPs -> FieldLabelStrings GhcRn
rnFieldLabelStrings (FieldLabelStrings fls) = FieldLabelStrings (fmap (fmap rnDotFieldOcc) fls)

{-
************************************************************************
*                                                                      *
        Arithmetic sequences
*                                                                      *
************************************************************************
-}

rnArithSeq :: ArithSeqInfo GhcPs -> RnM (ArithSeqInfo GhcRn, FreeNames)
rnArithSeq (From expr)
 = do { (expr', fvExpr) <- rnLExpr expr
      ; return (From expr', fvExpr) }

rnArithSeq (FromThen expr1 expr2)
 = do { (expr1', fvExpr1) <- rnLExpr expr1
      ; (expr2', fvExpr2) <- rnLExpr expr2
      ; return (FromThen expr1' expr2', fvExpr1 `plusFN` fvExpr2) }

rnArithSeq (FromTo expr1 expr2)
 = do { (expr1', fvExpr1) <- rnLExpr expr1
      ; (expr2', fvExpr2) <- rnLExpr expr2
      ; return (FromTo expr1' expr2', fvExpr1 `plusFN` fvExpr2) }

rnArithSeq (FromThenTo expr1 expr2 expr3)
 = do { (expr1', fvExpr1) <- rnLExpr expr1
      ; (expr2', fvExpr2) <- rnLExpr expr2
      ; (expr3', fvExpr3) <- rnLExpr expr3
      ; return (FromThenTo expr1' expr2' expr3',
                plusFNs [fvExpr1, fvExpr2, fvExpr3]) }

{-
************************************************************************
*                                                                      *
\subsubsection{@Stmt@s: in @do@ expressions}
*                                                                      *
************************************************************************
-}

type AnnoBody body
  = ( Outputable (body GhcPs)
    )

-- | Rename some Stmts
rnStmts :: AnnoBody body
        => HsStmtContextRn
        -> (body GhcPs -> RnM (body GhcRn, FreeNames))
           -- ^ How to rename the body of each statement (e.g. rnLExpr)
        -> [LStmt GhcPs (LocatedA (body GhcPs))]
           -- ^ Statements
        -> ([Name] -> RnM (thing, FreeNames))
           -- ^ if these statements scope over something, this renames it
           -- and returns the result.
        -> RnM (([LStmt GhcRn (LocatedA (body GhcRn))], thing), FreeNames)
-- Variables bound by the Stmts, and mentioned in thing_inside,
-- do not appear in the result FreeNames

rnStmts ctxt _ [] thing_inside
  = do { checkEmptyStmts ctxt
       ; (thing, fvs) <- thing_inside []
       ; return (([], thing), fvs) }

rnStmts ctxt rnBody (lstmt@(L loc _) : lstmts) thing_inside
  | null lstmts
  = setSrcSpanA loc $
    do { lstmt' <- checkLastStmt ctxt lstmt
       ; rnStmt ctxt rnBody lstmt' thing_inside }

  | otherwise
  = do { ((stmts1, (stmts2, thing)), fvs)
            <- setSrcSpanA loc                  $
               do { checkStmt ctxt lstmt
                  ; rnStmt ctxt rnBody lstmt $ \ bndrs1 ->
                    rnStmts ctxt rnBody lstmts  $ \ bndrs2 ->
                    thing_inside (bndrs1 ++ bndrs2) }
        ; return (((stmts1 ++ stmts2), thing), fvs) }

----------------------

{-
Note [Failing pattern matches in Stmts]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Many things desugar to HsStmts including monadic things like `do`
statements, pattern guards, and list comprehensions (see 'HsStmtContext' for an
exhaustive list). How we deal with pattern match failure is context-dependent.

 * In the case of list comprehensions and pattern guards we don't need any
   'fail' function; the desugarer ignores the fail function of 'BindStmt'
   entirely. So, for list comprehensions, the fail function is set to 'Nothing'
   for clarity.

* In the case of monadic contexts (e.g. monad comprehensions and do
   expressions) we want pattern match failure to be desugared to the
   'fail' function (from MonadFail type class).

At one point we failed to make this distinction, leading to #11216.
-}

rnStmt :: AnnoBody body
       => HsStmtContextRn
       -> (body GhcPs -> RnM (body GhcRn, FreeNames))
          -- ^ How to rename the body of the statement
       -> LStmt GhcPs (LocatedA (body GhcPs))
          -- ^ The statement
       -> ([Name] -> RnM (thing, FreeNames))
          -- ^ Rename the stuff that this statement scopes over
       -> RnM ( ([LStmt GhcRn (LocatedA (body GhcRn))], thing)
              , FreeNames)
-- Variables bound by the Stmt, and mentioned in thing_inside,
-- do not appear in the result FreeNames

rnStmt ctxt rnBody (L loc (LastStmt _ (L lb body) _)) thing_inside
  = do  { (body', fv_expr) <- rnBody body
        ; (ret_op, fvs1) <- if isMonadCompContext ctxt
                            then lookupStmtName ctxt returnMClassOpOcc
                            else return (noSyntaxExpr, emptyFNs)
                            -- The 'return' in a LastStmt is used only
                            -- for MonadComp; and we don't want to report
                            -- "not in scope: return" in other cases
                            -- #15607

        ; (thing,  fvs3) <- thing_inside []
        ; return (([L loc (LastStmt noExtField (L lb body') ret_op)]
                  , thing), fv_expr `plusFN` fvs1 `plusFN` fvs3) }

rnStmt ctxt rnBody (L loc (BodyStmt _ (L lb body) _ _)) thing_inside
  = do  { (body', fv_expr) <- rnBody body
        ; (then_op, fvs1)  <- lookupStmtName ctxt thenMClassOpOcc

        ; (guard_op, fvs2) <- if isComprehensionContext ctxt
                              then lookupStmtName ctxt guardMIdOcc
                              else return (noSyntaxExpr, emptyFNs)
                              -- Only list/monad comprehensions use 'guard'
                              -- Also for sub-stmts of same eg [ e | x<-xs, gd | blah ]
                              -- Here "gd" is a guard

        ; (thing, fvs3)    <- thing_inside []
        ; return ( ([L loc (BodyStmt noExtField (L lb body') then_op guard_op)]
                  , thing), fv_expr `plusFN` fvs1 `plusFN` fvs2 `plusFN` fvs3) }

rnStmt ctxt rnBody (L loc (BindStmt _ pat (L lb body))) thing_inside
  = do  { (body', fv_expr) <- rnBody body
                -- The binders do not scope over the expression
        ; (bind_op, fvs1) <- lookupStmtName ctxt bindMClassOpOcc

        ; rnPat (StmtCtxt ctxt) pat $ \ pat' -> do
        { (thing, fvs2) <- thing_inside (collectPatBinders CollNoDictBinders pat')
        ; (fail_op, fvs3) <- monadFailOp pat' ctxt
        ; let xbsrn = XBindStmtRn { xbsrn_bindOp = bind_op, xbsrn_failOp = fail_op }
        ; return (( [L loc (BindStmt xbsrn pat' (L lb body'))]
                  , thing),
                  fv_expr `plusFN` fvs1 `plusFN` fvs2 `plusFN` fvs3) }}
       -- fv_expr shouldn't really be filtered by the rnPatsAndThen
        -- but it does not matter because the names are unique

rnStmt _ _ (L loc (LetStmt _ binds)) thing_inside
  =     rnLocalBindsAndThen binds $ \binds' _ -> do
        { (thing, fvs) <- thing_inside (collectLocalBinders CollNoDictBinders binds')
        ; return ( ([L loc (LetStmt noAnn binds')], thing)
                 , fvs) }

rnStmt ctxt _ (L loc (ParStmt _ segs _ _)) thing_inside
  = do  { (mzip_op, fvs1)   <- lookupSyntaxExpr mzipIdOcc
        ; (bind_op, fvs2)   <- lookupStmtName ctxt bindMClassOpOcc
        ; (return_op, fvs3) <- lookupStmtName ctxt returnMClassOpOcc
        ; ((segs', thing), fvs4) <- rnParallelStmts (ParStmtCtxt ctxt) return_op segs thing_inside
        ; return (([L loc (ParStmt noExtField segs' mzip_op bind_op)], thing)
                 , fvs1 `plusFN` fvs2 `plusFN` fvs3 `plusFN` fvs4) }

rnStmt ctxt _ (L loc (TransStmt { trS_stmts = stmts, trS_by = by, trS_form = form
                              , trS_using = using })) thing_inside
  = do { -- Rename the 'using' expression in the context before the transform is begun
         (using', fvs1) <- rnLExpr using

         -- Rename the stmts and the 'by' expression
         -- Keep track of the variables mentioned in the 'by' expression
       ; ((stmts', (by', used_bndrs, thing)), fvs2)
             <- rnStmts (TransStmtCtxt ctxt) rnExpr stmts $ \ bndrs ->
                do { (by',   fvs_by) <- mapMaybeFvRn rnLExpr by
                   ; (thing, fvs_thing) <- thing_inside bndrs
                   ; let fvs = fvs_by `plusFN` fvs_thing
                         used_bndrs = filter (`elemNameSet` fvs) bndrs
                         -- The paper (Fig 5) has a bug here; we must treat any free variable
                         -- of the "thing inside", **or of the by-expression**, as used
                   ; return ((by', used_bndrs, thing), fvs) }

       -- Lookup `return`, `(>>=)` and `liftM` for monad comprehensions
       ; (return_op, fvs3) <- lookupStmtName ctxt returnMClassOpOcc
       ; (bind_op,   fvs4) <- lookupStmtName ctxt bindMClassOpOcc
       ; (fmap_op,   fvs5) <- case form of
                                ThenForm -> return (noExpr, emptyFNs)
                                _        -> lookupSyntaxExpr fmapClassOpOcc

       ; let all_fvs  = fvs1 `plusFN` fvs2 `plusFN` fvs3
                             `plusFN` fvs4 `plusFN` fvs5
             bndr_map = used_bndrs `zip` used_bndrs
             -- See Note [TransStmt binder map] in GHC.Hs.Expr

       ; traceRn "rnStmt: implicitly rebound these used binders:" (ppr bndr_map)
       ; return (([L loc (TransStmt { trS_ext = noExtField
                                    , trS_stmts = stmts', trS_bndrs = bndr_map
                                    , trS_by = by', trS_using = using', trS_form = form
                                    , trS_ret = return_op, trS_bind = bind_op
                                    , trS_fmap = fmap_op })], thing), all_fvs) }

rnParallelStmts :: forall thing. HsStmtContextRn
                -> SyntaxExpr GhcRn
                -> NonEmpty (ParStmtBlock GhcPs GhcPs)
                -> ([Name] -> RnM (thing, FreeNames))
                -> RnM ((NonEmpty (ParStmtBlock GhcRn GhcRn), thing), FreeNames)
-- Note [Renaming parallel Stmts]
rnParallelStmts ctxt return_op segs thing_inside
  = do { orig_lcl_env <- getLocalRdrEnv
       ; rn_segs (:|) orig_lcl_env [] segs }
  where
    -- The `cons` argument is how we cons the first `ParStmtBlock` onto the rest.
    -- It is called with `cons = (:)` or `cons = (:|)`.
    -- Thus, the return type `parStmtBlocks` is `[ParStmtBlock _ _]` or
    -- `NonEmpty (ParStmtBlock _ _)`, in turn.
    rn_segs :: (ParStmtBlock GhcRn GhcRn -> [ParStmtBlock GhcRn GhcRn] -> parStmtBlocks)
            -> LocalRdrEnv
            -> [Name] -> NonEmpty (ParStmtBlock GhcPs GhcPs)
            -> RnM ((parStmtBlocks, thing), FreeNames)
    rn_segs cons env bndrs_so_far (ParStmtBlock x stmts _ _ :| segs)
      = do { ((stmts', (used_bndrs, segs', thing)), fvs)
                    <- rnStmts ctxt rnExpr stmts $ \ bndrs ->
                       setLocalRdrEnv env       $ do
                       { ((segs', thing), fvs) <- rn_segs1 env (bndrs ++ bndrs_so_far) segs
                       ; let used_bndrs = filter (`elemNameSet` fvs) bndrs
                       ; return ((used_bndrs, segs', thing), fvs) }

           ; let seg' = ParStmtBlock x stmts' used_bndrs return_op
           ; return ((cons seg' segs', thing), fvs) }

    rn_segs1 _ bndrs [] = do
      { let (bndrs', dups) = removeDupsOn nameOccName bndrs
      ; mapM_ dupErr dups
      ; (thing, fvs) <- bindLocalNames bndrs' (thing_inside bndrs')
      ; return (([], thing), fvs) }
    rn_segs1 env bndrs (x:xs) = rn_segs (:) env bndrs (x:|xs)

    dupErr vs = addErr $ TcRnListComprehensionDuplicateBinding (NE.head vs)

{- Note [Renaming parallel Stmts]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Renaming parallel statements is painful.  Given, say
     [ a+c | a <- as, bs <- bss
           | c <- bs, a <- ds ]
Note that
  (a) In order to report "Defined but not used" about 'bs', we must
      rename each group of Stmts with a thing_inside whose FreeNames
      include at least {a,c}

  (b) We want to report that 'a' is illegally bound in both branches

  (c) The 'bs' in the second group must obviously not be captured by
      the binding in the first group

To satisfy (a) we nest the segments.
To satisfy (b) we check for duplicates just before thing_inside.
To satisfy (c) we reset the LocalRdrEnv each time.
-}

{- *********************************************************************
*                                                                      *
                Lookups for known-occ names
*                                                                      *
********************************************************************* -}

lookupStmtName :: HasDebugCallStack => HsStmtContextRn
               -> KnownOcc -> RnM (SyntaxExpr GhcRn, FreeNames)
lookupStmtName ctxt n
  -- For GRHSs (ctxt=PatGuard), list comprehensions, etc, we don't need
  -- return, >>=, >> etc. Looking them up is a waste of time; and early
  -- ghc-internal modules (e.g. GHC.Internal.Types) those functions
  -- don't even exist
  | not (rebindableContext ctxt)
  = return (noSyntaxExpr, emptyFNs)

  | otherwise  -- Respect -XRebindableSyntax
  = do { (expr, fvs) <- lookupSyntaxExpr n
       ; return (SyntaxExprRn expr, fvs) }

-- | Is this a context where we respect RebindableSyntax?
-- but ListComp are never rebindable
rebindableContext :: HsStmtContextRn -> Bool
rebindableContext ctxt = case ctxt of
  HsDoStmt flavour -> rebindableDoStmtContext flavour
  PatGuard {}      -> False
  ParStmtCtxt   c  -> rebindableContext c     -- Look inside to
  TransStmtCtxt c  -> rebindableContext c     -- the parent context

rebindableDoStmtContext :: HsDoFlavour -> Bool
rebindableDoStmtContext flavour = case flavour of
  ListComp     -> False
  DoExpr {}    -> True
  MonadComp    -> True
  GhciStmtCtxt -> True   -- I suppose?

{-
************************************************************************
*                                                                      *
\subsubsection{Errors}
*                                                                      *
************************************************************************
-}

checkEmptyStmts :: HsStmtContextRn -> RnM ()
-- We've seen an empty sequence of Stmts... is that ok?
checkEmptyStmts ctxt
  = mapM_ (addErr . TcRnEmptyStmtsGroup) mb_err
  where
    mb_err = case ctxt of
      PatGuard {}      -> Nothing -- Pattern guards can be empty
      ParStmtCtxt {}   -> Just EmptyStmtsGroupInParallelComp
      TransStmtCtxt {} -> Just EmptyStmtsGroupInTransformListComp
      HsDoStmt flav    -> Just $ EmptyStmtsGroupInDoNotation flav

----------------------
checkLastStmt :: AnnoBody body
              => HsStmtContextRn
              -> LStmt GhcPs (LocatedA (body GhcPs))
              -> RnM (LStmt GhcPs (LocatedA (body GhcPs)))
checkLastStmt ctxt lstmt@(L loc stmt)
  = case ctxt of
      HsDoStmt ListComp  -> check_comp
      HsDoStmt MonadComp -> check_comp
      HsDoStmt DoExpr{}  -> check_do
      _         -> check_other
  where
    check_do    -- Expect BodyStmt, and change it to LastStmt
      = case stmt of
          BodyStmt _ e _ _ -> return (L loc (mkLastStmt e))
          LastStmt {}      -> return lstmt   -- "Deriving" clauses may generate a
                                             -- LastStmt directly (unlike the parser)
          _                -> do { addErr $ TcRnLastStmtNotExpr ctxt
                                          $ UnexpectedStatement stmt
                                 ; return lstmt }


    check_comp  -- Expect LastStmt; this should be enforced by the parser!
      = case stmt of
          LastStmt {} -> return lstmt
          _           -> pprPanic "checkLastStmt" (ppr lstmt)

    check_other -- Behave just as if this wasn't the last stmt
      = do { checkStmt ctxt lstmt; return lstmt }

-- Checking when a particular Stmt is ok
checkStmt :: AnnoBody body
          => HsStmtContextRn
          -> LStmt GhcPs (LocatedA (body GhcPs))
          -> RnM ()
checkStmt ctxt (L _ stmt)
  = do { dflags <- getDynFlags
       ; case okStmt dflags ctxt stmt of
           IsValid      -> return ()
           NotValid ext -> addErr $
              TcRnUnexpectedStatementInContext
                ctxt (UnexpectedStatement stmt) ext }

------------
emptyInvalid :: Validity' (Maybe LangExt.Extension)
emptyInvalid = NotValid Nothing -- Invalid, and no extension to suggest

okStmt, okDoStmt, okCompStmt, okParStmt
   :: DynFlags -> HsStmtContextRn
   -> Stmt GhcPs (LocatedA (body GhcPs)) -> Validity' (Maybe LangExt.Extension)
-- Return Nothing if OK, (Just extra) if not ok
-- The "extra" is an SDoc that is appended to a generic error message

okStmt dflags ctxt stmt
  = case ctxt of
      PatGuard {}        -> okPatGuardStmt stmt
      ParStmtCtxt ctxt   -> okParStmt  dflags ctxt stmt
      HsDoStmt flavour   -> okDoFlavourStmt dflags flavour ctxt stmt
      TransStmtCtxt ctxt -> okStmt dflags ctxt stmt

okDoFlavourStmt
  :: DynFlags -> HsDoFlavour -> HsStmtContextRn
  -> Stmt GhcPs (LocatedA (body GhcPs)) -> Validity' (Maybe LangExt.Extension)
okDoFlavourStmt dflags flavour ctxt stmt = case flavour of
      DoExpr{}     -> okDoStmt   dflags ctxt stmt
      GhciStmtCtxt -> okDoStmt   dflags ctxt stmt
      ListComp     -> okCompStmt dflags ctxt stmt
      MonadComp    -> okCompStmt dflags ctxt stmt

-------------
okPatGuardStmt :: Stmt GhcPs (LocatedA (body GhcPs)) -> Validity' (Maybe LangExt.Extension)
okPatGuardStmt stmt
  = case stmt of
      BodyStmt {} -> IsValid
      BindStmt {} -> IsValid
      LetStmt {}  -> IsValid
      _           -> emptyInvalid

-------------
okParStmt dflags ctxt stmt
  = case stmt of
      LetStmt _ (HsIPBinds {}) -> emptyInvalid
      _                        -> okStmt dflags ctxt stmt

----------------
okDoStmt _ _ stmt
  = case stmt of
       BindStmt {} -> IsValid
       LetStmt {}  -> IsValid
       BodyStmt {} -> IsValid
       _           -> emptyInvalid

----------------
okCompStmt dflags _ stmt
  = case stmt of
       BindStmt {} -> IsValid
       LetStmt {}  -> IsValid
       BodyStmt {} -> IsValid
       ParStmt {}  -> IsValid
       TransStmt {}
         | LangExt.TransformListComp `xopt` dflags -> IsValid
         | otherwise -> NotValid (Just LangExt.TransformListComp)
       LastStmt {} -> emptyInvalid  -- Should not happen (dealt with by checkLastStmt)

---------
checkTupleSection :: [HsTupArg GhcPs] -> RnM ()
checkTupleSection args
  = do  { tuple_section <- xoptM LangExt.TupleSections
        ; checkErr (all tupArgPresent args || tuple_section) msg }
  where
    msg :: TcRnMessage
    msg = TcRnIllegalTupleSection

---------
sectionErr :: HsExpr GhcPs -> TcRnMessage
sectionErr = TcRnSectionWithoutParentheses

---------

monadFailOp :: LPat GhcRn
            -> HsStmtContextRn
            -> RnM (FailOperator GhcRn, FreeNames)
monadFailOp pat ctxt = do
    strict <- xoptM LangExt.Strict
    hscEnv <- getTopEnv
    rdrEnv <- getGlobalRdrEnv
    comps <- getCompleteMatchesTcM
        -- If the pattern is irrefutable (e.g.: wildcard, tuple, ~pat, etc.)
        -- we should not need to fail.
    if | isIrrefutableHsPat strict (irrefutableConLikeRn hscEnv rdrEnv comps) pat
       -> return (Nothing, emptyFNs)

        -- For non-monadic contexts (e.g. guard patterns, list
        -- comprehensions, etc.) we should not need to fail, or failure is handled in
        -- a different way. See Note [Failing pattern matches in Stmts].
       | not (isMonadStmtContext ctxt)
       -> return (Nothing, emptyFNs)

       | otherwise
       -> getMonadFailOp ctxt

{-
Note [Monad fail : Rebindable syntax, overloaded strings]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Given the code
  foo x = do { Just y <- x; return y }

we expect it to desugar as
  foo x = x >>= \r -> case r of
                        Just y  -> return y
                        Nothing -> fail "Pattern match error"

But with RebindableSyntax and OverloadedStrings, we really want
it to desugar thus:
  foo x = x >>= \r -> case r of
                        Just y  -> return y
                        Nothing -> fail (fromString "Patterm match error")

So, in this case, we synthesize the function
  \x -> fail (fromString x)

(rather than plain 'fail') for the 'fail' operation. This is done in
'getMonadFailOp'.

-}
getMonadFailOp :: HsStmtContextRn -> RnM (FailOperator GhcRn, FreeNames) -- Syntax expr fail op
getMonadFailOp ctxt
 = do { xOverloadedStrings <- fmap (xopt LangExt.OverloadedStrings) getDynFlags
      ; xRebindableSyntax <- fmap (xopt LangExt.RebindableSyntax) getDynFlags
      ; (fail, fvs) <- reallyGetMonadFailOp xRebindableSyntax xOverloadedStrings
      ; return (Just fail, fvs)
      }
  where
    reallyGetMonadFailOp rebindableSyntax overloadedStrings
      | rebindableSyntax && overloadedStrings = do
        (failName, failFvs) <- lookupSyntaxName failMClassOpOcc
        (fromStringExpr, fromStringFvs) <- lookupSyntaxExpr fromStringClassOpOcc
        let arg_lit = mkVarOccFS (fsLit "arg")
        arg_name <- newSysName arg_lit
        let arg_syn_expr = nlHsVar arg_name
            body :: LHsExpr GhcRn =
              nlHsApp (noLocA (genHsVar failName))
                      (nlHsApp (noLocA $ fromStringExpr) arg_syn_expr)
        let failAfterFromStringExpr :: HsExpr GhcRn =
              unLoc $ mkHsLam (noLocA [noLocA $ VarPat noExtField $ noLocA arg_name]) body
        let failAfterFromStringSynExpr :: SyntaxExpr GhcRn =
              mkSyntaxExpr failAfterFromStringExpr
        return (failAfterFromStringSynExpr, failFvs `plusFN` fromStringFvs)
      | otherwise = lookupStmtName ctxt failMClassOpOcc


{- *********************************************************************
*                                                                      *
              Generating code for ExpandedThingRn
      See Note [Handling overloaded and rebindable constructs]
*                                                                      *
********************************************************************* -}

-- | Expand `HsIf` if rebindable syntax is turned on
--   See Note [Handling overloaded and rebindable constructs]
rnHsIf :: LHsExpr GhcPs -> LHsExpr GhcPs -> LHsExpr GhcPs -> RnM (HsExpr GhcRn, FreeNames)
rnHsIf p b1 b2
  = do { (p',  fvP)  <- rnLExpr p
       ; (b1', fvB1) <- rnLExpr b1
       ; (b2', fvB2) <- rnLExpr b2
       ; let fvs_if = plusFNs [fvP, fvB1, fvB2]
             rn_if  = HsIf noExtField  p' b1' b2'

       -- Deal with rebindable syntax
       ; mb_ite <- lookupIfThenElse
       ; case mb_ite of
            Nothing  -- Non rebindable-syntax case
              -> return (rn_if, fvs_if)

            Just ite_name   -- Rebindable-syntax case
              -> do { let ds_if = genHsApps ite_name [p', b1', b2']
                          fvs   = plusFNs [fvs_if, unitFN ite_name]
                    ; return (mkExpandedExpr rn_if ds_if, fvs) } }

-----------------------------------------
-- Bits and pieces for RecordDotSyntax.
--
-- See Note [Overview of record dot syntax] in GHC.Hs.Expr.

-- mkGetField arg field calculates a get_field @field arg expression.
-- e.g. z.x = mkGetField z x = get_field @x z
mkGetField :: Name -> LHsExpr GhcRn -> LocatedAn NoEpAnns FieldLabelString -> HsExpr GhcRn
mkGetField get_field arg field = unLoc (head $ mkGet get_field (arg :| []) field)

-- mkSetField a field b calculates a set_field @field expression.
-- e.g mkSetSetField a field b = set_field @"field" a b (read as "set field 'field' to a on b").
-- NB: the order of aruments is specified by GHC Proposal 583: HasField redesign.
mkSetField :: Name -> LHsExpr GhcRn -> LocatedAn NoEpAnns FieldLabelString -> LHsExpr GhcRn -> HsExpr GhcRn
mkSetField set_field a (L _ (FieldLabelString field)) b =
  genHsApp (genHsApp (genHsVar set_field `genAppType` genHsTyLit field) b) a

mkGet :: Name -> NonEmpty (LHsExpr GhcRn) -> LocatedAn NoEpAnns FieldLabelString -> NonEmpty (LHsExpr GhcRn)
mkGet get_field l@(r :| _) (L _ (FieldLabelString field)) =
  wrapGenSpan (genHsApp (genHsVar get_field `genAppType` genHsTyLit field) r) NE.<| l

mkSet :: Name -> LHsExpr GhcRn -> (LocatedAn NoEpAnns FieldLabelString, LHsExpr GhcRn) -> LHsExpr GhcRn
mkSet set_field acc (field, g) = wrapGenSpan (mkSetField set_field g field acc)

-- mkProjection fields calculates a projection.
-- e.g. .x = mkProjection [x] = getField @"x"
--      .x.y = mkProjection [.x, .y] = (.y) . (.x) = getField @"y" . getField @"x"
mkProjection :: Name -> Name -> NonEmpty FieldLabelString -> HsExpr GhcRn
mkProjection getFieldName circName (field :| fields) = foldl' f (proj field) fields
  where
    f :: HsExpr GhcRn -> FieldLabelString -> HsExpr GhcRn
    f acc field = genHsApps circName $ map wrapGenSpan [proj field, acc]

    proj :: FieldLabelString -> HsExpr GhcRn
    proj (FieldLabelString f) = genHsVar getFieldName `genAppType` genHsTyLit f

-- mkProjUpdateSetField calculates functions representing dot notation record updates.
-- e.g. Suppose an update like foo.bar = 1.
--      We calculate the function \a -> setField @"foo" a (setField @"bar" (getField @"foo" a) 1).
mkProjUpdateSetField :: Name -> Name -> LHsRecProj GhcRn (LHsExpr GhcRn) -> (LHsExpr GhcRn -> LHsExpr GhcRn)
mkProjUpdateSetField get_field set_field (L _ (HsFieldBind { hfbLHS = (L _ (FieldLabelStrings flds')), hfbRHS = arg } ))
  = let {
      ; flds = NE.map (fmap (unLoc . dfoLabel)) flds'
      ; final = last flds  -- quux
      ; fields = init flds   -- [foo, bar, baz]
      ; getters = \a -> foldl' (mkGet get_field) (a :| []) fields  -- Ordered from deep to shallow.
          -- [getField@"baz"(getField@"bar"(getField@"foo" a), getField@"bar"(getField@"foo" a), getField@"foo" a, a]
      ; zips = \a -> (final, head (getters a)) : zip (reverse fields) (tail (getters a)) -- Ordered from deep to shallow.
          -- [("quux", getField@"baz"(getField@"bar"(getField@"foo" a)), ("baz", getField@"bar"(getField@"foo" a)), ("bar", getField@"foo" a), ("foo", a)]
      }
    in (\a -> foldl' (mkSet set_field) arg (zips a))
          -- setField@"foo" (a) (setField@"bar" (getField @"foo" (a))(setField@"baz" (getField @"bar" (getField @"foo" (a)))(setField@"quux" (getField @"baz" (getField @"bar" (getField @"foo" (a))))(quux))))

mkRecordDotUpd :: Name -> Name -> LHsExpr GhcRn -> [LHsRecUpdProj GhcRn] -> HsExpr GhcRn
mkRecordDotUpd get_field set_field exp updates = foldl' fieldUpdate (unLoc exp) updates
  where
    fieldUpdate :: HsExpr GhcRn -> LHsRecUpdProj GhcRn -> HsExpr GhcRn
    fieldUpdate acc lpu =  unLoc $ (mkProjUpdateSetField get_field set_field lpu) (wrapGenSpan acc)

rnHsUpdProjs :: [LHsRecUpdProj GhcPs] -> RnM ([LHsRecUpdProj GhcRn], FreeNames)
rnHsUpdProjs us = do
  (u, fvs) <- unzip <$> mapM rnRecUpdProj us
  pure (u, plusFNs fvs)
  where
    rnRecUpdProj :: LHsRecUpdProj GhcPs -> RnM (LHsRecUpdProj GhcRn, FreeNames)
    rnRecUpdProj (L l (HsFieldBind _ fs arg pun))
      = do { (arg, fv) <- rnLExpr arg
           ; return $
               (L l (HsFieldBind {
                         hfbAnn = noAnn
                       , hfbLHS = fmap rnFieldLabelStrings fs
                       , hfbRHS = arg
                       , hfbPun = pun }), fv ) }
