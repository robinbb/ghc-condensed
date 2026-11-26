-- Test type errors contain field names, not selector names


data T = MkT { x :: Int }

y = x x

main = return ()
