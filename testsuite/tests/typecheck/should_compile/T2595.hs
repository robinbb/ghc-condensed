module Foo where

data Foo = forall a . Foo { foo :: a -> a, bar :: Int }

x :: Foo
x = Foo { foo = id, bar = 3 }

f :: Foo -> Foo
f r = r { foo = id }

g :: Foo -> Foo
g r = r { bar = 3 }
