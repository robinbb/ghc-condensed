-- | This module provides the operators that let do-notation bind the
-- result of a monadic computation into a 'Code' under @RebindableSyntax@.
--
-- @
-- {-\# LANGUAGE RebindableSyntax \#-}
-- import Prelude hiding ((>>=), (>>))
-- import Language.Haskell.TH.CodeDo
--
-- myExample :: Monad m => Code m a -> Code m a -> Code m a
-- myExample opt1 opt2 =
--   do
--    x <- someSideEffect               -- This one is of type `M Bool`
--    if x then opt1 else opt2
-- @
module Language.Haskell.TH.CodeDo((>>=), (>>)) where

import Language.Haskell.TH.Syntax
import Prelude(Monad)

-- | Module over monad operator for 'Code'
(>>=) :: Monad m => m a -> (a -> Code m b) -> Code m b
(>>=) = bindCode
(>>) :: Monad m => m a -> Code m b -> Code m b
(>>)  = bindCode_
