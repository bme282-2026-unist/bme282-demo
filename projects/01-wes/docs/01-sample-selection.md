# 01 — Sample selection

**Produces:** [`../../../data/PRJNA896722/PRJNA896722.samples.tsv`](../../../data/PRJNA896722/PRJNA896722.samples.tsv)
and [`../../../data/PRJNA896722/SAMPLES.md`](../../../data/PRJNA896722/SAMPLES.md) —
78 exomes resolved to 26 named cell lines with tumor / blood / cell-line labels.

## The problem

ENA hands you 156 rows that look like this:

```text
run_accession  sample_accession  sample_alias             sample_title
SRR22269317    SAMN31703555      KCLB18MES0289.recal.bam  Human sample from Homo sapiens
SRR22272512    SAMN31563425      KCLB18MES0289_1.fastq.gz Human sample from Homo sapiens
```

Nothing there says *SNU-3987*, nothing says *tumor* or *blood*, and the two rows
above are the same biological sample. Before any of this data is usable for
teaching, three questions have to be answered:

1. Which runs are duplicates of each other?
2. Which cell line does each sample come from?
3. Which sample is the tumor, which is the blood, and which is the cell line?

## 1. Deduplicating the runs

Every sample in PRJNA896722 was submitted twice — once as FASTQ, once as a
recalibrated BAM — and ENA generates FASTQ from both, so all 156 rows have a
populated `fastq_ftp`. The `SAMN` accessions differ between the two copies, so
deduplicating on BioSample does not work.

`sample_alias` is the only field that gives it away, because it carries the
submitter's sample name plus the original filename:

```bash
tail -n +2 PRJNA896722.runs.tsv | cut -f14 \
  | sed 's/\.recal\.bam$//; s/_1\.fastq\.gz$//' \
  | sort | uniq -c | awk '{print $1}' | sort | uniq -c
#   78 2       every alias appears exactly twice
```

156 runs → 78 samples. Keep the FASTQ-submitted run of each pair (the
`SRR22272xxx` series); it is the submitter's original data rather than reads
that have been aligned, recalibrated and converted back.

The full argument, with the file-count difference between the two run types, is
in [`../../../data/PRJNA896722/README.md`](../../../data/PRJNA896722/README.md#the-156-runs-are-78-samples).

## 2. Naming the cell lines

The ENA metadata never names a cell line. `sample_title` is the placeholder
`Human sample from Homo sapiens` on all 156 rows.

The names are in the **NCBI BioSample** records behind each `SAMN` accession.
Those carry `tissue`, `cell_type` and `isolate`, and `isolate` holds values of
the form `SNU-3978_5` — the cell line plus an index that distinguishes the
patient's three samples.

The 26 names obtained this way were cross-checked against two independent
sources:

- Table 1 of the Scientific Data descriptor,
  <https://www.nature.com/articles/s41597-023-02365-y/tables/1>
- the KCLB glioblastoma catalog search,
  <https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=Glioblastoma&qt=name>

## 3. Tumor, blood, or cell line

The submitter's internal aliases turn out to be allocated in consecutive
triples, one patient per triple, in a fixed order:

```text
KCLB18MES0281  SNU-3978  tumor
KCLB18MES0282  SNU-3978  blood
KCLB18MES0283  SNU-3978  cell_line
KCLB18MES0284  SNU-3980  tumor
KCLB18MES0285  SNU-3980  blood
KCLB18MES0286  SNU-3980  cell_line
```

This pattern was **not** trusted on its own — the assignment comes from the
BioSample `isolate` index and `tissue` attributes, and the triple structure is
what confirms it holds for all 26 patients with no gaps and no leftovers.

An early version of the table had only the 26 cell-line samples in it, on the
assumption that tumor and blood were not in this BioProject. They were. Finding
the other 52 samples is what made somatic calling possible for project 1, and it
is the reason `SAMPLES.md` has three accession columns instead of one.

## KCLB catalog numbers

The KCLB catalog number is the five-digit zero-padded numeric part of the SNU
name:

```text
SNU-3978  ->  KCLB No. 03978
SNU-4116  ->  KCLB No. 04116
```

The `KCLB18MES0281`-style values in `sample_alias` are the study's own internal
identifiers and are unrelated to catalog numbering. `KCLB18MES0281` is not
catalog number 0281. Both appear in the final table, in separate columns, so
this stops being confusing.

## The teaching subset

Six of the 26 cell lines were picked for the class:

```text
SNU-3987  SNU-4054  SNU-4071  SNU-4072  SNU-4098  SNU-5026
```

They are complete triples with reasonable read depth, and together they are
88 GB rather than 699 GB — small enough that six students can each take one
without contending for disk or bandwidth. They are staged at
`/work/class/bme282.2026/pub/PRJNA896722/six/` and listed in
[`../metadata/samples.six.tsv`](../metadata/samples.six.tsv).

Nothing stops you from using one of the other 20; they are all in
`.../PRJNA896722/total/` and in
[`../metadata/samples.all.tsv`](../metadata/samples.all.tsv).

## What to check

```bash
cd ../../../data/PRJNA896722

tail -n +2 PRJNA896722.samples.tsv | wc -l                       # 78
tail -n +2 PRJNA896722.samples.tsv | cut -f3 | sort | uniq -c    # 26 each
tail -n +2 PRJNA896722.samples.tsv | cut -f1 | sort | uniq -c | awk '$1!=3'   # empty
tail -n +2 PRJNA896722.samples.tsv | cut -f5 | sort | uniq -d    # empty
```

## Caveats

- Tumor, blood and cell line from one patient are **matched, not replicates**.
  The cell line has been through selection in culture; it will not match its
  parent tumor variant for variant, and that difference is itself an
  interesting thing to measure.
- The KCLB links in `SAMPLES.md` are search URLs, not permanent records. They
  reflect the current catalog.
- The tumor/blood pairing is what enables somatic calling. Calling a cell line
  against the patient's blood measures tumor evolution *and* culture adaptation
  together, and cannot separate them.
