{-# LANGUAGE GADTs                      #-}
{-# LANGUAGE TypeFamilies               #-}
{-# LANGUAGE PolyKinds                  #-}

module T5716a where


data family DF a 
data instance DF a = Bar (Bar a)

