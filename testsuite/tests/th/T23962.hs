{-# LANGUAGE Haskell2010, TemplateHaskell #-}

import Data.Kind (Type)
import Data.Typeable (Proxy (Proxy))
import Language.Haskell.TH (runQ)
import Language.Haskell.TH.Ppr (pprint)

main =
  runQ [|typeOf (Proxy :: Proxy Type)|]
  >>= putStrLn . pprint
