module Main where

import Control.Exception (SomeException, try, evaluate)
import Etna.Result (PropertyResult(..))
import Etna.Witnesses
  ( witness_ribbon_width_floor_case_lineLen3
  , witness_ribbon_width_floor_case_lineLen7
  , witness_fuse_annotated_docs_case_a
  , witness_fuse_annotated_docs_case_z
  , witness_alter_annotations_balanced_case_a
  , witness_alter_annotations_balanced_case_b
  , witness_rtw_indent_blank_lines_case_2_0
  , witness_rtw_indent_blank_lines_case_3_1
  )
import System.Exit (exitFailure, exitSuccess)

cases :: [(String, PropertyResult)]
cases =
  [ ("witness_ribbon_width_floor_case_lineLen3",     witness_ribbon_width_floor_case_lineLen3)
  , ("witness_ribbon_width_floor_case_lineLen7",     witness_ribbon_width_floor_case_lineLen7)
  , ("witness_fuse_annotated_docs_case_a",    witness_fuse_annotated_docs_case_a)
  , ("witness_fuse_annotated_docs_case_z",    witness_fuse_annotated_docs_case_z)
  , ("witness_alter_annotations_balanced_case_a",    witness_alter_annotations_balanced_case_a)
  , ("witness_alter_annotations_balanced_case_b",    witness_alter_annotations_balanced_case_b)
  , ("witness_rtw_indent_blank_lines_case_2_0",            witness_rtw_indent_blank_lines_case_2_0)
  , ("witness_rtw_indent_blank_lines_case_3_1",            witness_rtw_indent_blank_lines_case_3_1)
  ]

main :: IO ()
main = do
  results <- mapM forceCase cases
  let failures =
        [ (n, msg) | (n, Fail msg) <- results ] ++
        [ (n, "discard") | (n, Discard) <- results ]
  if null failures
    then do
      putStrLn $ "OK: all " ++ show (length cases) ++ " witnesses passed"
      exitSuccess
    else do
      mapM_ (\(n, m) -> putStrLn (n ++ ": FAIL: " ++ m)) failures
      exitFailure

forceCase :: (String, PropertyResult) -> IO (String, PropertyResult)
forceCase (n, v) = do
  r <- try (evaluate v) :: IO (Either SomeException PropertyResult)
  case r of
    Left e  -> pure (n, Fail ("exception: " ++ show e))
    Right p -> pure (n, p)
