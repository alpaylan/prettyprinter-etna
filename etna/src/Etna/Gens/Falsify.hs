module Etna.Gens.Falsify where

import           Data.List.NonEmpty (NonEmpty(..))
import qualified Test.Falsify.Generator as F
import qualified Test.Falsify.Range as FR

import Etna.Properties (RibbonArgs(..), FuseArgs(..), AlterAnnArgs(..), RtwArgs(..))

ne :: [a] -> NonEmpty a
ne []     = error "Etna.Gens.Falsify.ne: empty list"
ne (x:xs) = x :| xs

gen_ribbon_width_floor :: F.Gen RibbonArgs
gen_ribbon_width_floor = RibbonArgs <$> F.inRange (FR.between (1 :: Int, 20))

gen_fuse_annotated_docs :: F.Gen FuseArgs
gen_fuse_annotated_docs = FuseArgs <$> F.elem (ne ['A' .. 'Z'])

gen_alter_annotations_balanced :: F.Gen AlterAnnArgs
gen_alter_annotations_balanced = AlterAnnArgs <$> F.elem (ne ['A' .. 'Z'])

gen_rtw_indent_blank_lines :: F.Gen RtwArgs
gen_rtw_indent_blank_lines = do
  i1 <- F.inRange (FR.between (0 :: Int, 8))
  i2 <- F.inRange (FR.between (0 :: Int, 8))
  pure (RtwArgs i1 i2)
