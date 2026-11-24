import Prelude as P


-- Tests that the compiler suggests using -XQualifiedDo
-- when the user qualifies a do.
main = do
  print $ P.do
    x <- [1, 2]
    P.return x
