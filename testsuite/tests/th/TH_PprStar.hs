{-# LANGUAGE TemplateHaskell, TypeApplications #-}

module TH_PprStar where

import qualified Data.Kind as K
import Data.Proxy
import Language.Haskell.TH
import System.IO

do t <- [t| (Proxy @K.Type String -> K.Type) -> Either K.Type ((K.Type -> K.Type) -> K.Type) |]
   runIO $ do hPutStrLn stderr (pprint t)
   return []
