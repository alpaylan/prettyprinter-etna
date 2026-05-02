{-# LANGUAGE OverloadedStrings #-}
module Etna.Properties where

import qualified Data.Text as T
import           Prettyprinter
import           Prettyprinter.Internal
                   ( Doc(Empty)
                   , SimpleDocStream(..)
                   , alterAnnotationsS
                   , removeTrailingWhitespace
                   )
import           Prettyprinter.Render.Util.StackMachine (renderSimplyDecorated)

import Etna.Result

------------------------------------------------------------------------------
-- Variant 1: ribbon_width_round_d4cd9e1f_1
-- "Compute ribbon width with floor instead of round"
------------------------------------------------------------------------------

-- | Page width parameter for the ribbon-width property.
--
-- We pin the doc to @"a" <> 'softline'' <> "b"@ and the ribbon
-- fraction to @0.5@; the only freedom left is the page width
-- @lineLength@. With the fix, the ribbon is @floor (lineLength / 2)@,
-- so the @softline'@ is forced into a newline whenever the ribbon is
-- below 2 (i.e. lineLength <= 3). The pre-fix code uses 'round' (banker's
-- rounding), so for half-integer products like @3 * 0.5 = 1.5@ the
-- ribbon expands to 2 and the line is incorrectly kept flat.
newtype RibbonArgs = RibbonArgs { ribbonLineLen :: Int }
  deriving (Eq, Show)

-- | The doc and fraction are fixed; only @lineLength@ varies.
ribbonProbeDoc :: Doc ()
ribbonProbeDoc = "a" <> softline' <> "b"

ribbonFraction :: Double
ribbonFraction = 0.5

-- | Property: rendering 'ribbonProbeDoc' under
-- @AvailablePerLine n 0.5@ must produce the layout consistent with
-- @ribbonWidth = floor (n * 0.5)@. Concretely, the @softline'@ is a
-- newline iff @floor (n * 0.5) < 2@, i.e. @n < 4@.
property_ribbon_width_floor :: RibbonArgs -> PropertyResult
property_ribbon_width_floor (RibbonArgs n)
  | n < 1 || n > 40 = Discard
  | otherwise =
      let ribbon  = max 0 (min n (floor (fromIntegral n * ribbonFraction)))
          breaks  = ribbon < 2  -- "b" needs 1 col, current col after "a" is 1
          sdoc    = layoutPretty (LayoutOptions (AvailablePerLine n ribbonFraction)) ribbonProbeDoc
          expected :: SimpleDocStream ()
          expected
            | breaks    = SChar 'a' (SLine 0 (SChar 'b' SEmpty))
            | otherwise = SChar 'a' (SChar 'b' SEmpty)
      in if eqStream sdoc expected
            then Pass
            else Fail $
                   "lineLength=" ++ show n
                ++ ": expected " ++ show expected
                ++ ", got " ++ show sdoc

-- | Compare two 'SimpleDocStream's by structure (we never mention
-- annotations here so a polymorphic Eq is enough).
eqStream :: SimpleDocStream a -> SimpleDocStream b -> Bool
eqStream SEmpty SEmpty = True
eqStream SFail  SFail  = True
eqStream (SChar c1 r1) (SChar c2 r2) = c1 == c2 && eqStream r1 r2
eqStream (SText l1 t1 r1) (SText l2 t2 r2) =
    l1 == l2 && t1 == t2 && eqStream r1 r2
eqStream (SLine i1 r1) (SLine i2 r2) = i1 == i2 && eqStream r1 r2
eqStream _ _ = False

------------------------------------------------------------------------------
-- Variant 2: fuse_annotated_drops_content_b2c0a91e_1
-- "Fix fusion of annotated documents"
------------------------------------------------------------------------------

-- | Annotation tag for the fuse property.
--
-- The buggy 'fuse' rewrites @Annotated _ Empty@ to plain @Empty@,
-- losing the annotation push/pop pair. We exercise the bug by feeding
-- a doc whose body fuses to 'Empty' and then rendering through
-- 'renderSimplyDecorated' so that lost annotations show up as missing
-- @\<TAG\>...\</TAG\>@ markers.
newtype FuseArgs = FuseArgs { fuseAnn :: Char }
  deriving (Eq, Show)

-- | An annotated empty doc — produces the @Annotated _ Empty@ shape
-- that the buggy 'fuse' rewrites to plain @Empty@.
fuseProbeDoc :: Char -> Doc Char
fuseProbeDoc ann = annotate ann emptyDoc

-- | Render with explicit start/end markers around annotations so a
-- dropped annotation is visible in the output text.
renderTagged :: Doc Char -> T.Text
renderTagged =
  renderSimplyDecorated id
                        (\c -> T.pack ['<', c, '>'])
                        (\c -> T.pack ['<', '/', c, '>'])
  . layoutPretty defaultLayoutOptions

-- | Property: 'fuse' must preserve annotations even when the body is
-- empty. The fixed implementation keeps the @Annotated@ constructor;
-- the buggy implementation discards it.
property_fuse_annotated_docs :: FuseArgs -> PropertyResult
property_fuse_annotated_docs (FuseArgs ann)
  | not (annValid ann) = Discard
  | otherwise =
      let doc       = fuseProbeDoc ann
          original  = renderTagged doc
          fused     = renderTagged (fuse Shallow doc)
          fusedDeep = renderTagged (fuse Deep doc)
      in if original == fused && original == fusedDeep
            then Pass
            else Fail $
                   "ann=" ++ show ann
                ++ "; original=" ++ show original
                ++ "; fuseShallow=" ++ show fused
                ++ "; fuseDeep=" ++ show fusedDeep

annValid :: Char -> Bool
annValid c = c >= 'A' && c <= 'Z'

------------------------------------------------------------------------------
-- Variant 3: alter_annotations_unbalanced_a3fc77b1_1
-- "Fix alterAnnotationsS removing only pushes, but not pops"
------------------------------------------------------------------------------

-- | Annotation tag for the alterAnnotationsS property.
--
-- The pre-fix implementation drops 'SAnnPush' frames whose annotation
-- maps to 'Nothing' but keeps the matching 'SAnnPop' — and on any pop
-- with an empty stack it raises 'panicPeekedEmpty'. So just stripping
-- annotations from a single annotated layout reliably crashes the
-- runtime under the buggy code.
newtype AlterAnnArgs = AlterAnnArgs { alterAnnTag :: Char }
  deriving (Eq, Show)

alterProbeDoc :: Char -> Doc Char
alterProbeDoc ann = annotate ann (pretty 'x')

-- | Property: stripping all annotations from
-- @annotate ann (pretty 'x')@ via 'alterAnnotationsS' must yield a
-- clean stream with no 'SAnnPush' or 'SAnnPop'.
--
-- We catch panics (from 'panicPeekedEmpty') in the runner via
-- @try \@SomeException@; for the witness, the buggy code raises an
-- error that bubbles to the test driver as a 'Fail'.
property_alter_annotations_balanced :: AlterAnnArgs -> PropertyResult
property_alter_annotations_balanced (AlterAnnArgs c)
  | not (annValid c) = Discard
  | otherwise =
      let layouted = layoutSmart defaultLayoutOptions (alterProbeDoc c)
          stripped = alterAnnotationsS (\_ -> Nothing) layouted
                       :: SimpleDocStream ()
          expected :: SimpleDocStream ()
          expected = SChar 'x' SEmpty
      in if eqStream stripped expected
           then Pass
           else Fail $
                  "ann=" ++ show c
               ++ "; expected " ++ show expected
               ++ ", got " ++ show stripped

------------------------------------------------------------------------------
-- Variant 4: rtw_indent_carries_to_blank_e7d52f8a_1
-- "removeTrailingWhitespace: drop indentation on intermediate blank lines"
------------------------------------------------------------------------------

-- | Indentation values for the rtw property.
--
-- We construct a 'SimpleDocStream' of the shape
-- @SLine i1 (SLine i2 (... (SLine iN (SChar 'x' SEmpty))))@ with
-- @N >= 2@. The fixed 'removeTrailingWhitespace' rewrites all
-- intermediate blank-line indents to 0 (otherwise the rendered text
-- has trailing whitespace). The pre-fix implementation lets the
-- intermediate indent leak through, so the output may equal the input.
data RtwArgs = RtwArgs
  { rtwI1 :: !Int
  , rtwI2 :: !Int
  } deriving (Eq, Show)

-- | Property: every intermediate 'SLine' produced by
-- 'removeTrailingWhitespace' (i.e. one not immediately followed by
-- non-whitespace text on its own line) must have indentation 0.
property_rtw_indent_blank_lines :: RtwArgs -> PropertyResult
property_rtw_indent_blank_lines (RtwArgs i1 i2)
  | not (rtwIndentValid i1) = Discard
  | not (rtwIndentValid i2) = Discard
  | otherwise =
      let sdoc :: SimpleDocStream ()
          sdoc = SLine i1 (SLine i2 (SChar 'x' SEmpty))
          -- Invariant: the leading SLine sits on an *empty* line (it is
          -- followed directly by another SLine), so its indent must be
          -- zero. The second SLine sits on a content line and keeps its
          -- own indent.
          expected :: SimpleDocStream ()
          expected = SLine 0 (SLine i2 (SChar 'x' SEmpty))
          actual   = removeTrailingWhitespace sdoc
      in if eqStream actual expected
           then Pass
           else Fail $
                  "(i1,i2)=" ++ show (i1, i2)
               ++ "; expected " ++ show expected
               ++ ", got " ++ show actual

rtwIndentValid :: Int -> Bool
rtwIndentValid n = n >= 0 && n <= 8
