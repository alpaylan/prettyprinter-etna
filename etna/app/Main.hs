{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import           Control.Exception     (SomeException, evaluate, try)
import           Data.IORef            (newIORef, readIORef, modifyIORef')
import           Data.Time.Clock       (diffUTCTime, getCurrentTime)
import           System.Environment    (getArgs)
import           System.Exit           (exitWith, ExitCode(..))
import           System.IO             (hFlush, stdout)
import           Text.Printf           (printf)

import           Etna.Result           (PropertyResult(..))
import qualified Etna.Properties       as P
import qualified Etna.Witnesses        as W
import qualified Etna.Gens.QuickCheck  as GQ
import qualified Etna.Gens.Hedgehog    as GH
import qualified Etna.Gens.Falsify     as GF
import qualified Etna.Gens.SmallCheck  as GS

import qualified Test.QuickCheck                    as QC
import qualified Hedgehog                           as HH
import qualified Test.Falsify.Generator             as FG
import qualified Test.Falsify.Interactive           as FI
import qualified Test.Falsify.Property              as FP
import qualified Test.SmallCheck                    as SC
import qualified Test.SmallCheck.Drivers            as SCD
import qualified Test.SmallCheck.Series             as SCS

allProperties :: [String]
allProperties =
  [ "RibbonWidthFloor"
  , "FuseAnnotatedDocs"
  , "AlterAnnotationsBalanced"
  , "RtwIndentBlankLines"
  ]

data Outcome = Outcome
  { oStatus :: String
  , oTests  :: Int
  , oCex    :: Maybe String
  , oErr    :: Maybe String
  }

main :: IO ()
main = do
  argv <- getArgs
  case argv of
    [tool, prop] -> dispatch tool prop
    _            -> do
      putStrLn "{\"status\":\"aborted\",\"error\":\"usage: etna-runner <tool> <property>\"}"
      hFlush stdout
      exitWith (ExitFailure 2)

dispatch :: String -> String -> IO ()
dispatch tool prop
  | prop /= "All" && prop `notElem` allProperties =
      emit tool prop "aborted" 0 0 Nothing (Just $ "unknown property: " ++ prop)
  | otherwise = do
      let targets = if prop == "All" then allProperties else [prop]
      mapM_ (runOne tool) targets

runOne :: String -> String -> IO ()
runOne tool prop = do
  t0 <- getCurrentTime
  result <- try (driver tool prop) :: IO (Either SomeException Outcome)
  t1 <- getCurrentTime
  let us = round ((realToFrac (diffUTCTime t1 t0) :: Double) * 1e6) :: Int
  case result of
    Left e  -> emit tool prop "aborted" 0 us Nothing (Just (show e))
    Right (Outcome status tests cex err) ->
      emit tool prop status tests us cex err

driver :: String -> String -> IO Outcome
driver "etna"       p = runWitnesses p
driver "quickcheck" p = runQuickCheck p
driver "hedgehog"   p = runHedgehog   p
driver "falsify"    p = runFalsify    p
driver "smallcheck" p = runSmallCheck p
driver _tool        _ = pure (Outcome "aborted" 0 Nothing (Just "unknown tool"))

------------------------------------------------------------------------------
-- Tool: etna (witness replay)
------------------------------------------------------------------------------

runWitnesses :: String -> IO Outcome
runWitnesses prop = case witnessesFor prop of
  []    -> pure (Outcome "aborted" 0 Nothing (Just ("no witnesses for " ++ prop)))
  cs    -> go cs 0
  where
    go [] n = pure (Outcome "passed" n Nothing Nothing)
    go ((name, mr):rest) n = do
      r <- try (evaluate mr) :: IO (Either SomeException PropertyResult)
      case r of
        Left e -> pure (Outcome "failed" (n + 1) (Just name) (Just (show e)))
        Right Pass     -> go rest (n + 1)
        Right Discard  -> go rest (n + 1)
        Right (Fail msg) -> pure (Outcome "failed" (n + 1) (Just name) (Just msg))

witnessesFor :: String -> [(String, PropertyResult)]
witnessesFor "RibbonWidthFloor" =
  [ ("witness_ribbon_width_floor_case_lineLen3", W.witness_ribbon_width_floor_case_lineLen3)
  , ("witness_ribbon_width_floor_case_lineLen7", W.witness_ribbon_width_floor_case_lineLen7)
  ]
witnessesFor "FuseAnnotatedDocs" =
  [ ("witness_fuse_annotated_docs_case_a", W.witness_fuse_annotated_docs_case_a)
  , ("witness_fuse_annotated_docs_case_z", W.witness_fuse_annotated_docs_case_z)
  ]
witnessesFor "AlterAnnotationsBalanced" =
  [ ("witness_alter_annotations_balanced_case_a", W.witness_alter_annotations_balanced_case_a)
  , ("witness_alter_annotations_balanced_case_b", W.witness_alter_annotations_balanced_case_b)
  ]
witnessesFor "RtwIndentBlankLines" =
  [ ("witness_rtw_indent_blank_lines_case_2_0", W.witness_rtw_indent_blank_lines_case_2_0)
  , ("witness_rtw_indent_blank_lines_case_3_1", W.witness_rtw_indent_blank_lines_case_3_1)
  ]
witnessesFor _ = []

------------------------------------------------------------------------------
-- Tool: quickcheck
------------------------------------------------------------------------------

runQuickCheck :: String -> IO Outcome
runQuickCheck "RibbonWidthFloor" =
  qcDrive (QC.forAll GQ.gen_ribbon_width_floor (qcProp P.property_ribbon_width_floor))
runQuickCheck "FuseAnnotatedDocs" =
  qcDrive (QC.forAll GQ.gen_fuse_annotated_docs (qcProp P.property_fuse_annotated_docs))
runQuickCheck "AlterAnnotationsBalanced" =
  qcDrive (QC.forAll GQ.gen_alter_annotations_balanced (qcProp P.property_alter_annotations_balanced))
runQuickCheck "RtwIndentBlankLines" =
  qcDrive (QC.forAll GQ.gen_rtw_indent_blank_lines (qcProp P.property_rtw_indent_blank_lines))
runQuickCheck p = pure (Outcome "aborted" 0 Nothing (Just ("unknown property: " ++ p)))

qcProp :: (a -> PropertyResult) -> a -> QC.Property
qcProp f args = case f args of
  Pass     -> QC.property True
  Discard  -> QC.discard
  Fail msg -> QC.counterexample msg (QC.property False)

qcDrive :: QC.Property -> IO Outcome
qcDrive p = do
  res <- try (QC.quickCheckWithResult
                QC.stdArgs { QC.maxSuccess = 200, QC.chatty = False }
                p)
           :: IO (Either SomeException QC.Result)
  case res of
    Left e -> pure (Outcome "failed" 1 Nothing (Just (show e)))
    Right (QC.Success { QC.numTests = n }) -> pure (Outcome "passed" n Nothing Nothing)
    Right (QC.Failure { QC.numTests = n, QC.failingTestCase = tc }) ->
      pure (Outcome "failed" n (Just (concat tc)) Nothing)
    Right (QC.GaveUp  { QC.numTests = n }) -> pure (Outcome "aborted" n Nothing (Just "QuickCheck gave up"))
    Right (QC.NoExpectedFailure { QC.numTests = n }) ->
      pure (Outcome "aborted" n Nothing (Just "no expected failure"))

------------------------------------------------------------------------------
-- Tool: hedgehog
------------------------------------------------------------------------------

runHedgehog :: String -> IO Outcome
runHedgehog "RibbonWidthFloor" =
  hhDrive GH.gen_ribbon_width_floor P.property_ribbon_width_floor
runHedgehog "FuseAnnotatedDocs" =
  hhDrive GH.gen_fuse_annotated_docs P.property_fuse_annotated_docs
runHedgehog "AlterAnnotationsBalanced" =
  hhDrive GH.gen_alter_annotations_balanced P.property_alter_annotations_balanced
runHedgehog "RtwIndentBlankLines" =
  hhDrive GH.gen_rtw_indent_blank_lines P.property_rtw_indent_blank_lines
runHedgehog p = pure (Outcome "aborted" 0 Nothing (Just ("unknown property: " ++ p)))

hhDrive :: Show a => HH.Gen a -> (a -> PropertyResult) -> IO Outcome
hhDrive gen f = do
  let test = HH.property $ do
        args <- HH.forAll gen
        case f args of
          Pass     -> pure ()
          Discard  -> HH.discard
          Fail msg -> do
            HH.annotate msg
            HH.failure
  res <- try (HH.check test) :: IO (Either SomeException Bool)
  case res of
    Left e      -> pure (Outcome "failed" 1 Nothing (Just (show e)))
    Right True  -> pure (Outcome "passed" 200 Nothing Nothing)
    Right False -> pure (Outcome "failed" 1 Nothing Nothing)

------------------------------------------------------------------------------
-- Tool: falsify
------------------------------------------------------------------------------

runFalsify :: String -> IO Outcome
runFalsify "RibbonWidthFloor" =
  fsDrive GF.gen_ribbon_width_floor P.property_ribbon_width_floor
runFalsify "FuseAnnotatedDocs" =
  fsDrive GF.gen_fuse_annotated_docs P.property_fuse_annotated_docs
runFalsify "AlterAnnotationsBalanced" =
  fsDrive GF.gen_alter_annotations_balanced P.property_alter_annotations_balanced
runFalsify "RtwIndentBlankLines" =
  fsDrive GF.gen_rtw_indent_blank_lines P.property_rtw_indent_blank_lines
runFalsify p = pure (Outcome "aborted" 0 Nothing (Just ("unknown property: " ++ p)))

fsDrive
  :: Show a
  => FG.Gen a
  -> (a -> PropertyResult)
  -> IO Outcome
fsDrive gen f = do
  let prop = do
        args <- FP.gen gen
        case f args of
          Pass     -> pure ()
          Discard  -> FP.discard
          Fail msg -> FP.testFailed (show args ++ ": " ++ msg)
  res <- try (FI.falsify prop) :: IO (Either SomeException (Maybe String))
  case res of
    Left e          -> pure (Outcome "failed" 1 Nothing (Just (show e)))
    Right Nothing   -> pure (Outcome "passed" 100 Nothing Nothing)
    Right (Just msg) -> pure (Outcome "failed" 1 (Just msg) Nothing)

------------------------------------------------------------------------------
-- Tool: smallcheck
------------------------------------------------------------------------------

runSmallCheck :: String -> IO Outcome
runSmallCheck "RibbonWidthFloor" =
  scDrive GS.series_ribbon_width_floor P.property_ribbon_width_floor
runSmallCheck "FuseAnnotatedDocs" =
  scDrive GS.series_fuse_annotated_docs P.property_fuse_annotated_docs
runSmallCheck "AlterAnnotationsBalanced" =
  scDrive GS.series_alter_annotations_balanced P.property_alter_annotations_balanced
runSmallCheck "RtwIndentBlankLines" =
  scDrive GS.series_rtw_indent_blank_lines P.property_rtw_indent_blank_lines
runSmallCheck p = pure (Outcome "aborted" 0 Nothing (Just ("unknown property: " ++ p)))

scDrive
  :: Show a
  => SCS.Series IO a
  -> (a -> PropertyResult)
  -> IO Outcome
scDrive series f = do
  countRef <- newIORef (0 :: Int)
  let depth = 5
      check args = SC.monadic $ do
        modifyIORef' countRef (+1)
        pure $ case f args of
          Pass    -> True
          Discard -> True
          Fail _  -> False
      smTest = SC.over series check
  res <- try (SCD.smallCheckM depth smTest)
           :: IO (Either SomeException (Maybe SCD.PropertyFailure))
  n <- readIORef countRef
  case res of
    Left e          -> pure (Outcome "failed" n Nothing (Just (show e)))
    Right Nothing   -> pure (Outcome "passed" n Nothing Nothing)
    Right (Just pf) -> pure (Outcome "failed" n (Just (show pf)) Nothing)

------------------------------------------------------------------------------
-- Output (single JSON line, exit 0 except on argv error)
------------------------------------------------------------------------------

emit :: String -> String -> String -> Int -> Int -> Maybe String -> Maybe String -> IO ()
emit tool prop status tests us cex err = do
  let q = quoteJSON
      esc Nothing  = "null"
      esc (Just s) = q s
  printf "{\"status\":%s,\"tests\":%d,\"discards\":0,\"time\":\"%dus\",\"counterexample\":%s,\"error\":%s,\"tool\":%s,\"property\":%s}\n"
    (q status) tests us (esc cex) (esc err) (q tool) (q prop)
  hFlush stdout

quoteJSON :: String -> String
quoteJSON s = '"' : concatMap esc s ++ "\""
  where
    esc '"'  = "\\\""
    esc '\\' = "\\\\"
    esc '\n' = "\\n"
    esc '\r' = "\\r"
    esc '\t' = "\\t"
    esc c | fromEnum c < 0x20 = printf "\\u%04x" (fromEnum c)
          | otherwise = [c]
