{-# Language TemplateHaskell #-}

module T12130 where

import T12130a hiding (Block)

b = $(block)
