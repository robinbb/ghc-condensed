{-# LANGUAGE Haskell2010 #-}
{-# LANGUAGE TemplateHaskell #-}

-- Need to enable the unused imports warning to trigger the bug.
{-# OPTIONS_GHC -Wunused-imports #-}

module T23240 ( test ) where
import T23240_aux ( D, mkD )

test :: D
test = $$mkD
