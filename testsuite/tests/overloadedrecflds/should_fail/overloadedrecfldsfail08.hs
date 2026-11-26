{-# LANGUAGE TypeFamilies #-}

data family F a
data instance F Int  = MkFInt  { x :: Int }
data instance F Bool = MkFBool { y :: Bool }

-- No data type has both these fields, but they belong to the same
-- lexical parent (F).  This used to confuse the renamer.
foo e = e { x = 3, y = True }

main = return ()
