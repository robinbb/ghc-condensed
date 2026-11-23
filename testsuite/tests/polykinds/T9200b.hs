{-# LANGUAGE TypeFamilies #-}

module T9200b where

---------
--- test a closed type family with a kind-annotated binder
type family F (a :: k) where
  F True = False
  F False = True
  F x = x
