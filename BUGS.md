# prettyprinter — Injected Bugs

Wadler/Leijen pretty-printer combinator library (quchen/prettyprinter). Workload narrowed to the `prettyprinter` sub-package; modern HEAD is the base, each patch reverse-applies a fix to install the original bug.

Total mutations: 4

## Bug Index

| # | Variant | Name | Location | Injection | Fix Commit |
|---|---------|------|----------|-----------|------------|
| 1 | `alter_annotations_unbalanced_a3fc77b1_1` | `alter_annotations_drops_only_pushes` | `prettyprinter/src/Prettyprinter/Internal.hs:1584` | `patch` | `5729c19b2a319e21635e92a5bdbf9b1ee4d48052` |
| 2 | `fuse_annotated_drops_content_b2c0a91e_1` | `fuse_drops_annotation_on_empty_body` | `prettyprinter/src/Prettyprinter/Internal.hs:1666` | `patch` | `ff555e19b7b17a74f16e6fb062256a57dabe4d92` |
| 3 | `ribbon_width_round_d4cd9e1f_1` | `ribbon_width_uses_round` | `prettyprinter/src/Prettyprinter/Internal.hs:1897` | `patch` | `f289c1782e564b24aa967f2cf42e65a0496e29d5` |
| 4 | `rtw_indent_carries_to_blank_e7d52f8a_1` | `rtw_propagates_indent_on_blank_lines` | `prettyprinter/src/Prettyprinter/Internal.hs:1743` | `patch` | `6ffbc8912c246329e8a811c97e266bea63315841` |

## Property Mapping

| Variant | Property | Witness(es) |
|---------|----------|-------------|
| `alter_annotations_unbalanced_a3fc77b1_1` | `AlterAnnotationsBalanced` | `witness_alter_annotations_balanced_case_a`, `witness_alter_annotations_balanced_case_b` |
| `fuse_annotated_drops_content_b2c0a91e_1` | `FuseAnnotatedDocs` | `witness_fuse_annotated_docs_case_a`, `witness_fuse_annotated_docs_case_z` |
| `ribbon_width_round_d4cd9e1f_1` | `RibbonWidthFloor` | `witness_ribbon_width_floor_case_lineLen3`, `witness_ribbon_width_floor_case_lineLen7` |
| `rtw_indent_carries_to_blank_e7d52f8a_1` | `RtwIndentBlankLines` | `witness_rtw_indent_blank_lines_case_2_0`, `witness_rtw_indent_blank_lines_case_3_1` |

## Framework Coverage

| Property | quickcheck | hedgehog | falsify | smallcheck |
|----------|---------:|-------:|------:|---------:|
| `AlterAnnotationsBalanced` | ✓ | ✓ | ✓ | ✓ |
| `FuseAnnotatedDocs` | ✓ | ✓ | ✓ | ✓ |
| `RibbonWidthFloor` | ✓ | ✓ | ✓ | ✓ |
| `RtwIndentBlankLines` | ✓ | ✓ | ✓ | ✓ |

## Bug Details

### 1. alter_annotations_drops_only_pushes

- **Variant**: `alter_annotations_unbalanced_a3fc77b1_1`
- **Location**: `prettyprinter/src/Prettyprinter/Internal.hs:1584` (inside `alterAnnotationsS`)
- **Property**: `AlterAnnotationsBalanced`
- **Witness(es)**:
  - `witness_alter_annotations_balanced_case_a` — stripping annotations from `annotate 'A' (pretty 'x')` panics under the bug
  - `witness_alter_annotations_balanced_case_b` — same with annotation 'B'
- **Source**: internal — Fix alterAnnotationsS removing only pushes, but not pops
  > Before this fix, `alterAnnotationsS` (and therefore `unAnnotateS`, which is `alterAnnotationsS (const Nothing)`) dropped every `SAnnPush` whose annotation mapped to `Nothing`, but kept the matching `SAnnPop`. The unbalanced output crashed the StackMachine renderer with `panicPeekedEmpty`. The fix tracks a `[Remove|DontRemove]` stack so each removed push also drops its corresponding pop. The patch reverse-applies by removing the `Remove:` track for the `Nothing` branch.
- **Fix commit**: `5729c19b2a319e21635e92a5bdbf9b1ee4d48052` — Fix alterAnnotationsS removing only pushes, but not pops
- **Invariant violated**: For any annotated document `d`, `alterAnnotationsS (const Nothing) (layoutSmart def d)` produces a stream containing no `SAnnPush` and no `SAnnPop`. Equivalently, `unAnnotateS` does not panic on any well-formed annotated layout.
- **How the mutation triggers**: Reverse-applying the patch changes the `Nothing` branch from `go (Remove:stack) rest` to `go stack rest`. On a layout like `SAnnPush 'A' (SChar 'x' (SAnnPop SEmpty))`, the push is dropped but no `Remove` is recorded, so the matching pop sees an empty stack and triggers `panicPeekedEmpty`. The runner catches the exception via `try @SomeException` and reports `failed` with the panic message.

### 2. fuse_drops_annotation_on_empty_body

- **Variant**: `fuse_annotated_drops_content_b2c0a91e_1`
- **Location**: `prettyprinter/src/Prettyprinter/Internal.hs:1666` (inside `fuse`)
- **Property**: `FuseAnnotatedDocs`
- **Witness(es)**:
  - `witness_fuse_annotated_docs_case_a` — annotate 'A' (Empty<>Empty) must render as `<A></A>` both before and after fuse
  - `witness_fuse_annotated_docs_case_z` — same with annotation 'Z'
- **Source**: internal — Fix fusion of annotated documents (#114)
  > Before #114, `fuse` matched `Annotated _ Empty -> Empty`, dropping the annotation entirely whenever the body fused (or already was) `Empty`. Renderers that translate annotations into structured output (e.g. terminal colour codes, tree renderers, the `renderSimplyDecorated` stack machine) silently lost annotation boundaries on documents containing empty annotated children. The fix changes the case to `Annotated ann x -> Annotated ann (go x)`, so fusion descends into the body and never strips the annotation.
- **Fix commit**: `ff555e19b7b17a74f16e6fb062256a57dabe4d92` — Fix fusion of annotated documents (#114)
- **Invariant violated**: For every annotated document `d`, the rendered output of `d` (using a renderer that emits start/end markers around annotations) equals the rendered output of `fuse Shallow d` and of `fuse Deep d`.
- **How the mutation triggers**: Reverse-applying the patch reinstates the `Annotated _ Empty -> Empty` rewrite. A doc like `annotate ann (Empty <> Empty)` rewrites to `Empty` after fusion, so `renderSimplyDecorated` sees no `SAnnPush`/`SAnnPop` and emits an empty string, while the un-fused doc emits `<TAG></TAG>`.

### 3. ribbon_width_uses_round

- **Variant**: `ribbon_width_round_d4cd9e1f_1`
- **Location**: `prettyprinter/src/Prettyprinter/Internal.hs:1897` (inside `remainingWidth`)
- **Property**: `RibbonWidthFloor`
- **Witness(es)**:
  - `witness_ribbon_width_floor_case_lineLen3` — lineLength=3, ribbon=0.5: floor=1 forces newline; round=2 keeps flat
  - `witness_ribbon_width_floor_case_lineLen7` — lineLength=7, ribbon=0.5: floor=3 keeps flat; round=4 also keeps flat - this case demonstrates the property holds at non-discriminating widths
- **Source**: internal — Compute ribbon width with `floor` instead of `round` (#160)
  > Before #160, the ribbon-width clamp used `round` (banker's rounding). For half-integer products like `pageWidth * 0.5 = 1.5`, this rounded *up* to 2 instead of *down* to 1, letting documents occupy one extra column inside the ribbon. The fix swaps `round` for `floor`, so the ribbon never exceeds its nominal fraction.
- **Fix commit**: `f289c1782e564b24aa967f2cf42e65a0496e29d5` — Compute ribbon width with `floor` instead of `round` (#160)
- **Invariant violated**: Rendering `"a" <> softline' <> "b"` with `AvailablePerLine n 0.5` produces a layout consistent with `ribbonWidth = floor (n * 0.5)`. Equivalently, `softline'` becomes a hard newline iff `floor (n * 0.5) < 2`.
- **How the mutation triggers**: Reverse-applying the patch swaps `floor` for `round` in `remainingWidth`. For `n = 3` the ribbon goes from 1 (correct) to 2 (buggy), so `softline'` no longer breaks the line and the output becomes `SChar 'a' (SChar 'b' SEmpty)` instead of the expected `SChar 'a' (SLine 0 (SChar 'b' SEmpty))`.

### 4. rtw_propagates_indent_on_blank_lines

- **Variant**: `rtw_indent_carries_to_blank_e7d52f8a_1`
- **Location**: `prettyprinter/src/Prettyprinter/Internal.hs:1743` (inside `removeTrailingWhitespace.prependEmptyLines`)
- **Property**: `RtwIndentBlankLines`
- **Witness(es)**:
  - `witness_rtw_indent_blank_lines_case_2_0` — (i1=2, i2=0): leading SLine indent must zero out
  - `witness_rtw_indent_blank_lines_case_3_1` — (i1=3, i2=1): both intermediate indents must zero out
- **Source**: internal — Fix #93: rTW restores indentation in the wrong spot
  > Before #93 (and the earlier blank-line fix), `removeTrailingWhitespace` could re-emit the withheld indentation onto every intermediate empty `SLine` it produced from a run of blank lines, instead of zeroing them out. The historical patches edited an older `commitSpaces` shape that no longer exists; we synthesise an analogous mutation against the modern `prependEmptyLines` helper. Reverse-applying it makes intermediate blank lines carry the original indent again, so trailing whitespace re-appears in pretty output that goes through `removeTrailingWhitespace`.
- **Fix commits**:
  - `6ffbc8912c246329e8a811c97e266bea63315841` — Fix #93: rTW restores indentation in the wrong spot
  - `9ea5da0a4cd05cdbddcc98a8edd62f4d0bb45219` — Fix stripping of empty lines for real this time :-)
- **Invariant violated**: After `removeTrailingWhitespace`, every `SLine i rest` whose `rest` begins with another `SLine` (i.e. the line is blank) has indentation `i = 0`.
- **How the mutation triggers**: Reverse-applying the patch changes `prependEmptyLines is = foldr (\_ sds -> SLine 0 sds) sds0 is` to `foldr (\i sds -> SLine i sds) sds0 is`. Then `removeTrailingWhitespace (SLine 2 (SLine 0 (SChar 'x' SEmpty)))` returns `SLine 2 (SLine 0 (SChar 'x' SEmpty))` (with leading SLine indent 2) instead of the expected `SLine 0 (SLine 0 (SChar 'x' SEmpty))`.
