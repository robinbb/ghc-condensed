{-# LANGUAGE GADTs        #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE PolyKinds    #-}

module T6129 where

data family D a
data instance D a = DInt

data X a where
  X1 :: X DInt
