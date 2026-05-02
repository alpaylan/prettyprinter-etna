# prettyprinter — ETNA Tasks

Total tasks: 16

## Task Index

| Task | Variant | Framework | Property | Witness |
|------|---------|-----------|----------|---------|
| 001 | `alter_annotations_unbalanced_a3fc77b1_1` | quickcheck | `AlterAnnotationsBalanced` | `witness_alter_annotations_balanced_case_a` |
| 002 | `alter_annotations_unbalanced_a3fc77b1_1` | hedgehog | `AlterAnnotationsBalanced` | `witness_alter_annotations_balanced_case_a` |
| 003 | `alter_annotations_unbalanced_a3fc77b1_1` | falsify | `AlterAnnotationsBalanced` | `witness_alter_annotations_balanced_case_a` |
| 004 | `alter_annotations_unbalanced_a3fc77b1_1` | smallcheck | `AlterAnnotationsBalanced` | `witness_alter_annotations_balanced_case_a` |
| 005 | `fuse_annotated_drops_content_b2c0a91e_1` | quickcheck | `FuseAnnotatedDocs` | `witness_fuse_annotated_docs_case_a` |
| 006 | `fuse_annotated_drops_content_b2c0a91e_1` | hedgehog | `FuseAnnotatedDocs` | `witness_fuse_annotated_docs_case_a` |
| 007 | `fuse_annotated_drops_content_b2c0a91e_1` | falsify | `FuseAnnotatedDocs` | `witness_fuse_annotated_docs_case_a` |
| 008 | `fuse_annotated_drops_content_b2c0a91e_1` | smallcheck | `FuseAnnotatedDocs` | `witness_fuse_annotated_docs_case_a` |
| 009 | `ribbon_width_round_d4cd9e1f_1` | quickcheck | `RibbonWidthFloor` | `witness_ribbon_width_floor_case_lineLen3` |
| 010 | `ribbon_width_round_d4cd9e1f_1` | hedgehog | `RibbonWidthFloor` | `witness_ribbon_width_floor_case_lineLen3` |
| 011 | `ribbon_width_round_d4cd9e1f_1` | falsify | `RibbonWidthFloor` | `witness_ribbon_width_floor_case_lineLen3` |
| 012 | `ribbon_width_round_d4cd9e1f_1` | smallcheck | `RibbonWidthFloor` | `witness_ribbon_width_floor_case_lineLen3` |
| 013 | `rtw_indent_carries_to_blank_e7d52f8a_1` | quickcheck | `RtwIndentBlankLines` | `witness_rtw_indent_blank_lines_case_2_0` |
| 014 | `rtw_indent_carries_to_blank_e7d52f8a_1` | hedgehog | `RtwIndentBlankLines` | `witness_rtw_indent_blank_lines_case_2_0` |
| 015 | `rtw_indent_carries_to_blank_e7d52f8a_1` | falsify | `RtwIndentBlankLines` | `witness_rtw_indent_blank_lines_case_2_0` |
| 016 | `rtw_indent_carries_to_blank_e7d52f8a_1` | smallcheck | `RtwIndentBlankLines` | `witness_rtw_indent_blank_lines_case_2_0` |

## Witness Catalog

- `witness_alter_annotations_balanced_case_a` — stripping annotations from `annotate 'A' (pretty 'x')` panics under the bug
- `witness_alter_annotations_balanced_case_b` — same with annotation 'B'
- `witness_fuse_annotated_docs_case_a` — annotate 'A' (Empty<>Empty) must render as `<A></A>` both before and after fuse
- `witness_fuse_annotated_docs_case_z` — same with annotation 'Z'
- `witness_ribbon_width_floor_case_lineLen3` — lineLength=3, ribbon=0.5: floor=1 forces newline; round=2 keeps flat
- `witness_ribbon_width_floor_case_lineLen7` — lineLength=7, ribbon=0.5: floor=3 keeps flat; round=4 also keeps flat - this case demonstrates the property holds at non-discriminating widths
- `witness_rtw_indent_blank_lines_case_2_0` — (i1=2, i2=0): leading SLine indent must zero out
- `witness_rtw_indent_blank_lines_case_3_1` — (i1=3, i2=1): both intermediate indents must zero out
