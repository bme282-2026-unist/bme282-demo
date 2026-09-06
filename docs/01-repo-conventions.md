# Repository conventions

Every project directory in this repository has the same four parts. Use the
same shape in your own repository so that a script written for project 1 can be
adapted for project 3 without rearranging anything.

```text
projects/NN-name/
├── README.md      what this project is, and the order to do it in
├── docs/          one document per stage, numbered
├── scripts/       runnable scripts, numbered by stage
└── metadata/      sample sheets and small tables (TSV)
```

## Numbering

Documents and scripts are numbered so that `ls` shows the order of work.

```text
docs/01-sample-selection.md
docs/02-fastq-download.md
docs/03-variant-calling.md

scripts/00_fetch_ena_metadata.sh    00–09  metadata and setup
scripts/01_make_fastq_urls.sh
scripts/02_download_fastq.sh
scripts/10_bwa_map.sh               10–19  per-sample processing
scripts/20_strelka.sh               20–29  cohort / calling steps
```

Gaps in the numbering are deliberate; they leave room to insert a step later
without renaming everything downstream.

## Scripts

Scripts in this repository follow a few conventions, and yours should too:

- **`#!/usr/bin/env bash` and `set -euo pipefail`.** A pipeline that fails
  silently in step 3 and writes a truncated BAM in step 7 costs more time than
  it saves.
- **Arguments for what changes, environment variables for what does not.**
  The sample ID and its FASTQ files are arguments; the reference genome path,
  thread count and output root are environment variables with sensible
  defaults.
  ```bash
  ./10_bwa_map.sh SNU-4072_tumor R1.fastq.gz R2.fastq.gz     # arguments
  REF=/path/to/other.fa THREADS=8 ./10_bwa_map.sh ...        # overrides
  ```
- **The header comment is the usage message.** Every script prints its own
  header when run with no arguments, so the documentation cannot drift away
  from the code.
- **Idempotent by default.** If the output already exists, skip it and say so.
  Set `FORCE=1` to re-run. Downloads use `wget -c` so an interrupted transfer
  resumes rather than restarting.
- **Outputs go under `$OUT_DIR`, never next to the inputs.** The default is
  `results/` inside the project directory, which `.gitignore` excludes.

## Metadata

Sample sheets are tab-separated, with a header row, one sample per row, and
lower-case `snake_case` column names. Keep them small enough to read in a
terminal and to diff in git.

```tsv
sample_id	sample_type	cell_line	r1	r2
SNU-4072_tumor	tumor	SNU-4072	/work/.../SRR22272502_1.fastq.gz	/work/.../SRR22272502_2.fastq.gz
SNU-4072_blood	blood	SNU-4072	/work/.../SRR22272501_1.fastq.gz	/work/.../SRR22272501_2.fastq.gz
```

A sample sheet like this drives a whole batch from one loop:

```bash
tail -n +2 metadata/samples.tsv | while IFS=$'\t' read -r sid stype cl r1 r2; do
    ./scripts/10_bwa_map.sh "$sid" "$r1" "$r2"
done
```

## Sample IDs

Use `<CELL_LINE>_<SAMPLE_TYPE>`, e.g. `SNU-4072_tumor`, `SNU-4072_blood`,
`SNU-4072_cell_line`. The ID is written into the BAM read group (`SM:` tag) and
carried through to the VCF sample column, so a name that is meaningless at the
FASTQ stage will still be meaningless three steps later when you are looking at
variants.

Do not use bare SRR accessions as sample IDs. `SRR22272502` tells you nothing
about which cell line or which tissue you are looking at.

## Documentation

Each stage document answers four questions, in this order:

1. **What** the stage produces.
2. **How** to run it — the exact commands.
3. **What to check** before moving on.
4. **What went wrong** — problems actually hit, and how they were resolved.

The fourth part is the one worth writing down. A pipeline that worked on the
first try teaches nobody anything.

All documentation in this repository is written in English.
