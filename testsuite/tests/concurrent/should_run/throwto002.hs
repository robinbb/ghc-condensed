import Control.Concurrent
import Control.Exception
import Control.Monad.Fix
import Data.Array
import System.Environment
import Control.Monad
import GHC.Conc
import Data.IORef

main = do
  r <- newIORef 0
  _ <- mfix $ \ ~(t1, t2) -> do
    t1 <- mask $ \restore -> forkIO (thread restore r t2)
    t2 <- mask $ \restore -> forkIO (thread restore r t1)
    return (t1, t2)
  threadDelay 1000000
  readIORef r >>= print . (/= 0)

thread restore r t = run
  where
    run = (restore $ forever $ do killThread t
                                  i <- atomicModifyIORef r (\i -> (i + 1, i))
                                  evaluate i)
             `catch` \(e::SomeException) -> run
