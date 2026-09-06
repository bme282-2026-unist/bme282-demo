# BME282 — Introduction to Genomics (2026)

Instructor-maintained **demo repository** for BME282 at UNIST.

This repository is a worked reference, not a submission template. Students keep
their own repositories for their own analyses; this one shows how the four
course projects are laid out, which shared data and references live on the
class server, and what the instructor actually ran to produce them.

## Course projects

| # | Directory | Topic | Status |
|---|---|---|---|
| 1 | [`projects/01-wes/`](projects/01-wes/) | Whole-exome sequencing (WES) of GBM patient-derived cell lines — germline and somatic variant calling | Data downloaded, pipeline drafted |
| 2 | [`projects/02-targeted-seq/`](projects/02-targeted-seq/) | PCR amplification of selected variant targets, followed by amplicon NGS and Sanger sequencing | Planned |
| 3 | [`projects/03-bulk-rnaseq/`](projects/03-bulk-rnaseq/) | Bulk RNA-seq of the same cell lines — expression and differential expression | Planned |
| 4 | [`projects/04-scrnaseq/`](projects/04-scrnaseq/) | Single-cell RNA-seq of related samples — clustering and cell-state analysis | Planned |

The four projects share one biological system: a panel of glioblastoma (GBM)
patient-derived cell lines from the Korean Cell Line Bank (KCLB). Project 1
finds the variants, project 2 validates a handful of them at the bench,
projects 3 and 4 ask what those cells are doing transcriptionally.

## Repository layout

```text
bme282-demo/
├── README.md                    this file
├── docs/                        course-wide documentation
│   ├── 00-server-setup.md       accounts, directories, disk, software
│   ├── 01-repo-conventions.md   how a project directory is organized
│   ├── 02-shared-data.md        what is already on the server, and where
│   └── 03-ena-downloads.md      how to pull public sequencing data from ENA
├── data/                        metadata only — never raw reads
│   └── PRJNA896722/             the GBM WES BioProject used by projects 1–3
│       ├── README.md
│       ├── SAMPLES.md           student-facing sample picker
│       ├── PRJNA896722.runs.tsv     raw ENA run report (156 runs)
│       └── PRJNA896722.samples.tsv  curated sample table (78 samples)
└── projects/
    ├── 01-wes/
    │   ├── README.md
    │   ├── docs/                what was done, in order
    │   ├── scripts/             runnable scripts
    │   └── metadata/            per-project sample sheets
    ├── 02-targeted-seq/
    ├── 03-bulk-rnaseq/
    └── 04-scrnaseq/
```

## Where the data lives

Sequencing data is **not** in this repository. Raw reads, reference genomes
and analysis outputs live on the class server under `/work/class/bme282.2026/`:

```text
/work/class/bme282.2026/
├── pub/                         read-only shared data (instructor-maintained)
│   ├── gencode.50/              GRCh38 primary assembly + GENCODE v50 annotation
│   └── PRJNA896722/
│       ├── total/               all 156 FASTQ runs (312 files, ~699 GB)
│       └── six/                 the six-cell-line teaching subset (36 files, ~88 GB)
└── <username>/                  your own working directory
```

See [`docs/02-shared-data.md`](docs/02-shared-data.md) for the full inventory and
[`docs/00-server-setup.md`](docs/00-server-setup.md) for how to get set up.

## Getting started

1. Read [`docs/00-server-setup.md`](docs/00-server-setup.md) and confirm you can
   log in to the class server and write to your own directory.
2. Read [`docs/01-repo-conventions.md`](docs/01-repo-conventions.md) and create
   your own repository with the same shape.
3. Work through [`projects/01-wes/README.md`](projects/01-wes/README.md), picking
   one cell line from [`data/PRJNA896722/SAMPLES.md`](data/PRJNA896722/SAMPLES.md).

## License

See [`LICENSE`](LICENSE).
