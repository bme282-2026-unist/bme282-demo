# Project 4 — Single-cell RNA-seq

Resolve the same biology one cell at a time: what cell states exist in a GBM
sample, in what proportions, and which of them the bulk measurement in project 3
was averaging over.

**Status:** planned. No dataset has been selected or downloaded yet.

## Why this comes last

Bulk RNA-seq gives one expression value per gene per sample — the mean across
however many cell states are in the dish or the tumor. That mean can move
because every cell changed a little, or because the proportion of one state
changed a lot. Bulk cannot tell those apart. Single-cell can, and project 3's
results are the thing project 4 is reinterpreting.

GBM is a good system for this: tumors carry several coexisting malignant
states along with substantial non-malignant content (myeloid cells,
oligodendrocytes, T cells), and the mixture varies between patients.

## Planned stages

| | Stage | Tools |
|---|---|---|
| 1 | Dataset selection and download | ENA / GEO / a published count matrix |
| 2 | Alignment and counting, or import of a published matrix | `cellranger` / `alevin-fry` / `STARsolo` |
| 3 | QC — empty droplets, doublets, mitochondrial fraction | `scanpy` / `Seurat`, `scrublet` |
| 4 | Normalization, HVG selection, dimensionality reduction | PCA, UMAP |
| 5 | Clustering and annotation | marker genes, reference-based labelling |
| 6 | Interpretation | cell-state proportions; malignant vs. non-malignant; comparison back to project 3 |

## Practical notes

- **Compute.** A 10x run is tens of thousands of cells and tens of gigabytes.
  `cellranger` wants a lot of RAM. Starting from a published count matrix is a
  legitimate choice and often the right one for a course project — the analysis
  questions are in stages 4–6, not in stage 2.
- **QC thresholds are decisions, not defaults.** Filtering on gene count and
  mitochondrial fraction changes which cells exist in your analysis. Write down
  what you chose and why, and check what the result would have been with a
  different cut.
- **Clusters are not cell types.** A cluster is an artifact of the resolution
  parameter until it has been annotated with markers and checked for stability.
- **Batch effects look like biology.** Two patients' cells will separate on the
  UMAP whether or not their cell states differ. Integrate deliberately, and
  know what integration has removed.

## Layout

```text
04-scrnaseq/
├── README.md
├── docs/        one document per stage, numbered — see ../../docs/01-repo-conventions.md
├── metadata/    sample sheet, cell annotations
└── scripts/     download/import, QC, clustering, annotation
```
