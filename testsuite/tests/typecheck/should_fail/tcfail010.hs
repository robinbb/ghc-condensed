module ShouldFail where

q :: [Int] -> [Int]
q = \ (y:z) -> z+2
