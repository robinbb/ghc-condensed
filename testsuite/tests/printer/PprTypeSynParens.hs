{-# LANGUAGE TypeFamilies #-}

import Data.Kind (Type)

class Compilable a where
   type CompileResult a :: Type

instance Compilable a => Compilable [a] where
   type CompileResult [a] = [CompileResult a]

instance Compilable a => Compilable (Maybe a) where
   type CompileResult (Maybe a) = Maybe (CompileResult a)

instance Compilable InterpreterStmt where
   type CompileResult InterpreterStmt = [Hask.Stmt]

instance Compilable ModuleSpan where
   type ((CompileResult ModuleSpan)) = Hask.Module

instance Compilable StatementSpan where
   type (CompileResult StatementSpan) = [Stmt]
