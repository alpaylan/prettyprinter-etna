module Etna.Gens.QuickCheck where

import qualified Test.QuickCheck as QC

import Etna.Properties (RibbonArgs(..), FuseArgs(..), AlterAnnArgs(..), RtwArgs(..))

gen_ribbon_width_floor :: QC.Gen RibbonArgs
gen_ribbon_width_floor = RibbonArgs <$> QC.choose (1, 20)

gen_fuse_annotated_docs :: QC.Gen FuseArgs
gen_fuse_annotated_docs = FuseArgs <$> QC.elements ['A' .. 'Z']

gen_alter_annotations_balanced :: QC.Gen AlterAnnArgs
gen_alter_annotations_balanced = AlterAnnArgs <$> QC.elements ['A' .. 'Z']

gen_rtw_indent_blank_lines :: QC.Gen RtwArgs
gen_rtw_indent_blank_lines = do
  i1 <- QC.choose (0, 8)
  i2 <- QC.choose (0, 8)
  pure (RtwArgs i1 i2)
