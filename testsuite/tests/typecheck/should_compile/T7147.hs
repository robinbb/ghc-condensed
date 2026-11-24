{-# LANGUAGE FunctionalDependencies #-}

module Prog where

class AddName i d | d->i where 
  addName :: d -> d

class Rec r struct | r->struct where
  mapRec :: (struct->struct) -> r -> r

-- We got a very bogus siguature for addNameRec in thc 7.6rc1
-- addNameRec :: forall r struct.
--                Recursive.Rec r struct
--                -> DefinedNames.AddName (GHC.Prim.Any *) struct
--                -> r
--                -> r

addNameRec x = mapRec addName x

instance AddName Int Bool where
  addName = error "urk"
instance AddName Float Char where
  addName = error "urk"

instance Rec Char Bool where
  mapRec = error "urk"
instance Rec Bool Char where
  mapRec = error "urk"


foo1 :: Char -> Char
foo1 = addNameRec 

foo2 :: Bool -> Bool
foo2 = addNameRec 
