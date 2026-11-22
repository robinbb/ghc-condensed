{-# LANGUAGE MagicHash #-}
-- See also TypeOf.hs

import GHC.Exts
import Data.Typeable

data CharHash = CharHash Char#

main :: IO ()
main = print $ typeRep (Proxy :: Proxy 'CharHash)
