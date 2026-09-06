# Project 3 — Bulk RNA-seq of GBM cell lines

Quantify gene expression in the same GBM cell lines used in project 1, and ask
what distinguishes them from each other.

**Status:** planned. No dataset has been selected or downloaded yet.

## Relationship to the other projects

Project 1 says what is broken in the genome. Project 3 says what the cell is
doing about it. The interesting questions live in the join between them:

- Does a cell line carrying a truncating variant in gene *X* express less of
  *X*?
- Are the cell lines with similar mutational profiles also similar
  transcriptionally?
- Is a somatic variant from project 1 visible in the RNA reads at all — and if
  so, at what allele fraction? (Allele-specific expression, from the same
  variant list project 2 validated.)

## Planned stages

| | Stage | Tools |
|---|---|---|
| 1 | Dataset selection and download | ENA / GEO — see [`../../docs/03-ena-downloads.md`](../../docs/03-ena-downloads.md) |
| 2 | Read QC and trimming | `fastp`, `fastqc`, `multiqc` |
| 3 | Quantification | `salmon` or `kallisto` (transcript-level), or `STAR` + `featureCounts` |
| 4 | Normalization and exploration | PCA, sample clustering, `DESeq2` |
| 5 | Differential expression | `DESeq2` |
| 6 | Interpretation | GSEA / over-representation against GBM subtype signatures |

## Reference

Already on the server — see [`../../docs/02-shared-data.md`](../../docs/02-shared-data.md):

```text
/work/class/bme282.2026/pub/gencode.50/
├── GRCh38.primary_assembly.genome.fa.gz
├── gencode.v50.primary_assembly.annotation.gtf.gz
└── gencode.v50.primary_assembly.annotation.gff3.gz
```

Use the **same genome build and annotation version** as project 1. Mixing
GENCODE releases between projects makes coordinates disagree in ways that are
tedious to debug and easy to avoid.

A transcriptome FASTA for `salmon`/`kallisto` can be derived from these two
files with `gffread`; ask before building one, since it belongs in `pub/`.

## Design notes

- **Replicates.** Differential expression needs biological replicates. Two cell
  lines with one library each is not an experiment with an *n*; it is two
  observations. Decide what is being compared, and what varies within a group,
  before choosing samples.
- **Cell lines are not tumors.** Expression in a cultured line reflects the
  culture as much as the tumor it came from. Statements about GBM biology need
  that caveat attached.
- **Batch.** If samples came from different submissions, run dates, or library
  prep protocols, that will be the first principal component. Check for it
  before believing any gene-level result.

## Layout

```text
03-bulk-rnaseq/
├── README.md
├── docs/        one document per stage, numbered — see ../../docs/01-repo-conventions.md
├── metadata/    sample sheet, experimental design table
└── scripts/     download, quantification, DE analysis
```
