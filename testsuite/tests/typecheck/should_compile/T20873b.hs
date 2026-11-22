

module T20873b where

import T20873b_aux (P)

type Q = P
  -- P = 'MkA is a promoted data constructor hidden behind a synonym,
  -- so that implementation details of M1 do not leak.
