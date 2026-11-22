{-# LANGUAGE UnliftedNewtypes #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE MagicHash #-}

module UnliftedNewtypesConstraintFamily where

import Data.Kind (Type,Constraint)

data family D (a :: Type) :: Constraint
