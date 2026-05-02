module Etna.Gens.Hedgehog where

import           Hedgehog (Gen)
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range

import Etna.Properties (RibbonArgs(..), FuseArgs(..), AlterAnnArgs(..), RtwArgs(..))

gen_ribbon_width_floor :: Gen RibbonArgs
gen_ribbon_width_floor = RibbonArgs <$> Gen.int (Range.linear 1 20)

gen_fuse_annotated_docs :: Gen FuseArgs
gen_fuse_annotated_docs = FuseArgs <$> Gen.element ['A' .. 'Z']

gen_alter_annotations_balanced :: Gen AlterAnnArgs
gen_alter_annotations_balanced = AlterAnnArgs <$> Gen.element ['A' .. 'Z']

gen_rtw_indent_blank_lines :: Gen RtwArgs
gen_rtw_indent_blank_lines = do
  i1 <- Gen.int (Range.linear 0 8)
  i2 <- Gen.int (Range.linear 0 8)
  pure (RtwArgs i1 i2)
