-- Check that CSP works for typed quotations.. there was no test for this
-- before apart from the deriving tests.
module TH_typed_csp where

bar = (\x -> [|| x ||]) ()
