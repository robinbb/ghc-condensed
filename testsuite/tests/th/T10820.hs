{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE LiberalTypeSynonyms #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE MagicHash #-}

module Main where

import Language.Haskell.TH.Syntax
import GHC.LanguageExtensions

main = do
  print $(isExtEnabled Cpp                  >>= lift)
  print $(isExtEnabled LiberalTypeSynonyms  >>= lift)
  print $(isExtEnabled TypeSynonymInstances >>= lift)
  print $(isExtEnabled MagicHash            >>= lift)
