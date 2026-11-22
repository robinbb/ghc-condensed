{-# LANGUAGE TemplateHaskell #-}
module ThDataDeclContext where

import Language.Haskell.TH

-- A data declaration built by Template Haskell may not carry a context
-- any more than one written in source may.
$(do a <- newName "a"
     pure [DataD [AppT (ConT ''Eq) (VarT a)] (mkName "T") [PlainTV a BndrReq] Nothing
             [NormalC (mkName "MkT") [(Bang NoSourceUnpackedness NoSourceStrictness, VarT a)]] []])
