{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE UnboxedSums #-}
{-# LANGUAGE UnboxedTuples #-}
module T12512 where

import GHC.Exts

class Wat1 (a :: TYPE ('TupleRep ['BoxedRep 'Lifted, 'BoxedRep 'Lifted]))
deriving instance Wat1 (# a, b #)

class Wat2 (a :: TYPE ('SumRep ['BoxedRep 'Lifted, 'BoxedRep 'Lifted]))
deriving instance Wat2 (# a | b #)
