{-# LANGUAGE FlexibleInstances #-}

-- Liberated incoherent-instance behaviour (#8141)

class C a b where foo :: (a,b)

instance {-# INCOHERENT #-} C Int b where foo = undefined
instance C a Int where foo = undefined

x :: (Int, Int)
x = foo

main = return ()
