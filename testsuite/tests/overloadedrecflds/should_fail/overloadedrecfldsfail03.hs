-- Test that a top-level definition with the same name as a record
-- field is rejected


foo = True

data T = MkT { foo :: Int }

main = print foo
