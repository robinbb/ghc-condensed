{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE AllowAmbiguousTypes #-}

module Bug where

instance BugClass ((s : sx) :: [r]) where
    bugList = testF @r @s

class BugClass k where
    bugList :: ()

testF :: forall a (b :: [a]). ()
testF = ()
