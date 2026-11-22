{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE TypeFamilies, FlexibleInstances, UndecidableInstances #-}

import GHC.TypeLits

data C = A | B

class Err (a :: C)

instance (TypeError ('Text "uh-oh")) => Err 'A
instance Err 'B
