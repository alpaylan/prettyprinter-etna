module Etna.Witnesses where

import Etna.Properties
import Etna.Result

-- Variant 1: ribbon_width_round
witness_ribbon_width_floor_case_lineLen3 :: PropertyResult
witness_ribbon_width_floor_case_lineLen3 =
  property_ribbon_width_floor (RibbonArgs 3)

witness_ribbon_width_floor_case_lineLen7 :: PropertyResult
witness_ribbon_width_floor_case_lineLen7 =
  property_ribbon_width_floor (RibbonArgs 7)

-- Variant 2: fuse_annotated_drops_content
witness_fuse_annotated_docs_case_a :: PropertyResult
witness_fuse_annotated_docs_case_a =
  property_fuse_annotated_docs (FuseArgs 'A')

witness_fuse_annotated_docs_case_z :: PropertyResult
witness_fuse_annotated_docs_case_z =
  property_fuse_annotated_docs (FuseArgs 'Z')

-- Variant 3: alter_annotations_unbalanced
witness_alter_annotations_balanced_case_a :: PropertyResult
witness_alter_annotations_balanced_case_a =
  property_alter_annotations_balanced (AlterAnnArgs 'A')

witness_alter_annotations_balanced_case_b :: PropertyResult
witness_alter_annotations_balanced_case_b =
  property_alter_annotations_balanced (AlterAnnArgs 'B')

-- Variant 4: rtw_indent_carries_to_blank
witness_rtw_indent_blank_lines_case_2_0 :: PropertyResult
witness_rtw_indent_blank_lines_case_2_0 =
  property_rtw_indent_blank_lines (RtwArgs 2 0)

witness_rtw_indent_blank_lines_case_3_1 :: PropertyResult
witness_rtw_indent_blank_lines_case_3_1 =
  property_rtw_indent_blank_lines (RtwArgs 3 1)
