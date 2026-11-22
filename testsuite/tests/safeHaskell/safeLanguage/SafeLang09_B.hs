{-# LANGUAGE FlexibleInstances #-}

-- Untrusted plugin! Don't wan't it changing behaviour of our
-- trusted code
module SafeLang09_B where

import SafeLang09_A

instance Pos a where
    res _ = False

instance {-# OVERLAPPING #-} Pos [Int] where
    res _ = error "This curry is poisoned!"

function :: Int
function = 3

