import Data.List (isPrefixOf)
import qualified Data.Set as S
import System.Process
import System.Environment

import Notes

usage :: IO a
usage = do
    putStrLn $ unlines
        [ "usage:"
        , "    lint-notes <mode>"
        , "    lint-notes <mode> @<response-file>"
        , "    lint-notes <mode> <file>"
        , ""
        , "valid modes:"
        , "  dump             dump all Note definitions and references"
        , "  defs             dump all Note definitions"
        , "  refs             dump all Note references"
        , "  unreferenced     dump all unreferenced Note definitions"
        , "  broken-refs      dump all references to missing Notes"
        ]
    fail "invalid usage"

main :: IO ()
main = do
    args <- getArgs

    let printNoteDefs = putStrLn . unlines . map showNoteDef
        printNoteRefs = putStrLn . unlines . map showNoteRef
        printNoteRefsSugg (bad, sugg) = do
          putStrLn . showNoteRef $ bad
          putStrLn $ "  >" ++ showNoteDef sugg


        parseMode :: String -> Maybe (NoteDb -> IO ())
        parseMode "dump"         = Just $ putStrLn . showNoteDb
        parseMode "unreferenced" = Just $ printNoteDefs . S.toList . unreferencedNotes
        parseMode "defs"         = Just $ printNoteDefs . allNoteDefs
        parseMode "refs"         = Just $ printNoteRefs . allNoteRefs
        parseMode "broken-refs"  = Just $ \notedb -> do
          putStrLn "Broken note references (target note not found!):"
          printNoteRefs . map fst . brokenNoteRefs $ notedb
        parseMode "broken-refs-suggest" = Just $ mapM_ printNoteRefsSugg . brokenNoteRefs
        parseMode _              = Nothing

    (mode, files) <- case args of
      [mode, "@-"] -> do
        files <- lines <$> getContents
        return (parseMode mode, files)
      [mode, '@':respFile] -> do
        files <- lines <$> readFile respFile
        return (parseMode mode, files)
      [mode] -> do
        let excludeList =
              [ "testsuite/tests/linters/notes.stdout"
              , "linters/lint-notes/test" ]
            -- The library submodules absorbed into the tree, and nofib, keep
            -- their own Notes; references inside them are not GHC's to check.
            absorbedLibraries =
              [
              "libraries/Cabal/", "libraries/Win32/", "libraries/array/",
              "libraries/binary/", "libraries/bytestring/", "libraries/containers/",
              "libraries/deepseq/", "libraries/directory/", "libraries/exceptions/",
              "libraries/file-io/", "libraries/filepath/", "libraries/haskeline/",
              "libraries/hpc/", "libraries/mtl/", "libraries/os-string/",
              "libraries/parsec/", "libraries/pretty/", "libraries/process/",
              "libraries/semaphore-compat/", "libraries/stm/", "libraries/template-haskell-lift/",
              "libraries/template-haskell-quasiquoter/", "libraries/terminfo/", "libraries/text/",
              "libraries/time/", "libraries/transformers/", "libraries/unix/",
              "libraries/xhtml/", "nofib/" ]
            excluded f = f `elem` excludeList || any (`isPrefixOf` f) absorbedLibraries
        files <- lines <$> readProcess "git" ["ls-tree", "--name-only", "-r", "HEAD"] ""
        return (parseMode mode, filter (not . excluded) files)
      _ -> usage

    case mode of
      Just run -> filesNotes files >>= run
      Nothing -> return ()

