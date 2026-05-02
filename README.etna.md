# prettyprinter — ETNA workload

This directory is a fork of [`quchen/prettyprinter`](https://github.com/quchen/prettyprinter)
turned into an ETNA workload for QuickCheck / Hedgehog / Falsify /
SmallCheck. Modern HEAD is the base; each `patches/<variant>.patch`
reverse-applies a fix to install a real historical bug.

## Monorepo narrowing

Upstream is a multi-package repo (`prettyprinter`,
`prettyprinter-ansi-terminal`, several `prettyprinter-compat-*` shims,
`prettyprinter-convert-ansi-wl-pprint`). The workload narrows
`cabal.project` to just `prettyprinter` plus the local `etna/` runner
package. The compat / convert / ansi-terminal sub-packages are not
built — none of the variants live there, and excluding them keeps the
toolchain matrix minimal.

## Layout

```
.                                # upstream fork (untouched)
  cabal.project                  # OURS — pins ghc-9.6.6, packages: prettyprinter + etna/
  etna.toml                      # OURS — manifest (single source of truth)
  patches/<variant>.patch        # OURS — bug-injection patches
  etna/                          # OURS — runner package
    etna-runner.cabal
    src/Etna/{Result,Properties,Witnesses}.hs
    src/Etna/Gens/{QuickCheck,Hedgehog,Falsify,SmallCheck}.hs
    app/Main.hs                  # CLI dispatcher (etna-runner <tool> <property>)
    test/Witnesses.hs            # cabal test-suite: every witness must equal Pass
  BUGS.md / TASKS.md             # generated; do not hand-edit
```

## Building

```sh
ghcup install ghc 9.6.6           # if not already
cabal build all
cabal test etna-witnesses         # base witnesses must all pass
```

## Running

From inside `etna/`:

```sh
cabal run etna-runner -- quickcheck RibbonWidthFloor
cabal run etna-runner -- hedgehog   FuseAnnotatedDocs
cabal run etna-runner -- falsify    AlterAnnotationsBalanced
cabal run etna-runner -- smallcheck RtwIndentBlankLines
cabal run etna-runner -- etna       <PropName>     # witness replay only
```

Each invocation prints a single JSON line to stdout and exits 0
(except on argv-parse error). The schema matches every other ETNA
runner:

```
{"status":"passed|failed|aborted","tests":N,"discards":0,
 "time":"<us>us","counterexample":"...|null","error":"...|null",
 "tool":"...","property":"..."}
```

## Validating a variant

```sh
git apply -R --whitespace=nowarn patches/<variant>.patch    # install bug
cabal test etna-witnesses                                   # must FAIL on the variant's witnesses
(cd etna && cabal run -v0 etna-runner -- quickcheck <Prop>) # must report failed
git apply --whitespace=nowarn patches/<variant>.patch       # restore base
```

All four variants are detected by all four backends; SmallCheck never
times out on this workload (the parameter spaces are small enough to
exhaust within depth 5).

## Variants at a glance

See `BUGS.md` for the full table. Brief:

- **ribbon_width_round_d4cd9e1f_1** — ribbon-width clamp uses `round`
  instead of `floor`. Half-fractional ribbons (e.g. `pageWidth=3,
  ribbon=0.5`) over-extend by one column, so `softline'` no longer
  forces a break.
- **fuse_annotated_drops_content_b2c0a91e_1** — `fuse` rewrites
  `Annotated _ Empty -> Empty`, dropping the annotation push/pop pair
  for any annotated empty doc.
- **alter_annotations_unbalanced_a3fc77b1_1** — `alterAnnotationsS`
  drops `SAnnPush` for Nothing-mapped annotations but keeps the
  matching `SAnnPop`. `unAnnotateS` panics on every annotated layout.
- **rtw_indent_carries_to_blank_e7d52f8a_1** — synthesised from the
  spirit of #93 / "Fix stripping of empty lines for real this time" against
  the modern `prependEmptyLines` helper. Intermediate blank lines
  re-acquire their original indent, regrowing trailing whitespace.

## GHC pin

`Falsify >= 0.2` requires `base >= 4.18`, so GHC 9.6 is the floor. We
pin 9.6.6 via `with-compiler:` in `cabal.project`. Don't bump.
