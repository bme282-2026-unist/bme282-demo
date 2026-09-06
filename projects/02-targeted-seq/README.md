# Project 2 — Targeted resequencing: PCR, amplicon NGS, and Sanger

Take a handful of variants that project 1 called, design primers around them,
amplify them from genomic DNA, and confirm them two independent ways: amplicon
NGS and Sanger sequencing.

**Status:** planned. Nothing has been run yet.

This is the project where the pipeline meets the bench. A variant caller emits
a PASS record; that record is a statistical claim about a pile of short reads,
not an observation of a molecule. Project 2 asks whether the claim survives a
different assay.

## Inputs

- Somatic and germline variant calls from
  [`../01-wes/`](../01-wes/) — the `*.PASS.vcf.gz` files
- Genomic DNA from the same cell lines (KCLB)

## Planned stages

| | Stage | Output |
|---|---|---|
| 1 | Variant selection — pick targets from the project 1 VCFs | `metadata/targets.tsv`, `metadata/targets.bed` |
| 2 | Primer design — flanking primers per target, checked for specificity | `metadata/primers.tsv` |
| 3 | Amplicon NGS analysis — align, count reads supporting ref vs. alt | per-target allele fractions |
| 4 | Sanger analysis — base-call the traces, compare to the expected genotype | per-target calls |
| 5 | Concordance — WES vs. amplicon NGS vs. Sanger | confirmation table |

## Picking targets

A variant worth taking to the bench is one that is:

- **biologically interesting** — in a gene with a known role in GBM, or a
  variant with a functional prediction worth testing;
- **well supported** — enough reads, a good `SomaticEVS`, not in a repeat or a
  region of ragged coverage;
- **amplifiable** — a unique primer pair can be placed 100–300 bp either side,
  which rules out most of what sits in segmental duplications;
- **visible to Sanger** — Sanger detects an allele at roughly 15–20% and above.
  A somatic variant at 5% VAF is real, callable by NGS, and invisible on a
  trace. Choosing one of those and then reporting "Sanger did not confirm it"
  is a conclusion about the assay, not about the variant.

Aim for a mix: a couple of high-confidence, high-VAF somatic variants, at least
one germline variant as a positive control, and — if you want to make the point
about assay sensitivity — one low-VAF somatic variant chosen deliberately.

## Why both NGS and Sanger

They fail differently, which is the whole point of running both.

| | Amplicon NGS | Sanger |
|---|---|---|
| Sensitivity | ~1% VAF | ~15–20% VAF |
| Output | read counts per allele | one trace, one consensus |
| Fails when | PCR/index bias, low-complexity amplicon | mixed alleles, low VAF, poor trace quality |
| Cost per target | low at scale | low at small scale |

A variant confirmed by both is confirmed. A variant confirmed by NGS but not by
Sanger is usually a real low-VAF variant. A variant confirmed by neither, at
high WES VAF, is a mapping artifact — go look at the BAM in IGV.

## Layout

```text
02-targeted-seq/
├── README.md
├── docs/        one document per stage, numbered — see ../../docs/01-repo-conventions.md
├── metadata/    targets.tsv, primers.tsv, sample sheets
└── scripts/     amplicon alignment and counting; Sanger trace handling
```
