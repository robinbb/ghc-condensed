{-# LANGUAGE TypeFamilies #-}

module OpenFamImplicitKv where

type family F a   -- non-injective

type family X :: F a
    -- Used to fail with:
    --
    --    • Couldn't match expected kind ‘F a1’ with actual kind ‘F a’
    --      NB: ‘F’ is a non-injective type family
    --      The type variable ‘a1’ is ambiguous
    --    • In the type family declaration for ‘X’
