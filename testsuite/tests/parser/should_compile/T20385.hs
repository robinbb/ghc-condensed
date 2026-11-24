{-# LANGUAGE MultiWayIf #-}

main = pure ()

foo :: forall a. a -> a
foo x = if | otherwise -> x
