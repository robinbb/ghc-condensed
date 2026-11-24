{-# LANGUAGE TemplateHaskell #-}
module ExtraConstraintsWildcardInPatternSplice where

foo $( [p| (_ :: _) |] ) = ()
