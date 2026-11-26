{-# LANGUAGE TemplateHaskell #-}

import Language.Haskell.TH (runQ)

{-
Test multiline string literals, GHC proposal 569
https://github.com/ghc-proposals/ghc-proposals/blob/master/proposals/0569-multiline-strings.rst
-}

main :: IO ()
main = do
  print =<< runQ [|
      """
      hello
      world
      """
    |]
