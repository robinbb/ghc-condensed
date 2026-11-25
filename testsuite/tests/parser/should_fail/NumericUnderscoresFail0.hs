
-- Test for underscores in numeric literals.
-- See #14473
-- This is a testcase for underscores in invalid positions.

main :: IO ()
main = do
    print [
            -- integer
            1000000_,
            _1000000
          ]
