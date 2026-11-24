{-# LANGUAGE MonadComprehensions #-}
{-# LANGUAGE RebindableSyntax #-}

module RepPolyMcBind where

import Data.Kind ( Type )
import GHC.Exts
import Prelude ( undefined )

(>>=)
  :: forall
        rep
        ( ma :: TYPE rep )
        ( a  :: Type )
        ( mb :: TYPE rep )
        ( mc :: TYPE rep )
  .  ma -> ( a -> mb ) -> mc
(>>=) = undefined

return :: forall rep (ma :: TYPE rep). () -> ma
return = undefined

foo :: forall rep (ma :: TYPE rep). () -> ma
foo _ = [ () | x <- undefined :: ma ]
