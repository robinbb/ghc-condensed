{-# LANGUAGE RecordWildCards #-}
module Main where

import qualified T5592a as MR (MyRecord(MyRecord, field))

main
  = do { let field = "Hello, world!"
             recd = MR.MyRecord {..}
       ; print recd }
