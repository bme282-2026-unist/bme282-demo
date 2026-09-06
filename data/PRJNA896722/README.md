# PRJNA896722 — GBM patient-derived cell line exomes

Whole-exome sequencing of 26 glioblastoma (GBM) patient-derived cell lines
established at the Korean Cell Line Bank (KCLB), each with matched tumor tissue
and matched blood from the same patient.

| | |
|---|---|
| BioProject | [PRJNA896722](https://www.ebi.ac.uk/ena/browser/view/PRJNA896722) |
| Library strategy | WXS (whole-exome), genomic, paired-end |
| Instrument | Illumina HiSeq 2500 (all 78 samples) |
| Patients / cell lines | 26 |
| Biological samples | 78 (26 tumor, 26 blood, 26 cell line) |
| ENA runs | 156 (see below) |
| Reads per sample | 30–150 M pairs |
| Total FASTQ | ~699 GB |
| Data descriptor | <https://www.nature.com/articles/s41597-023-02365-y> |

Used by project 1 (WES), and as the variant source for project 2
(targeted resequencing).

## Files in this directory

| File | Rows | What it is |
|---|---:|---|
| [`PRJNA896722.runs.tsv`](PRJNA896722.runs.tsv) | 156 | The raw ENA run report, unmodified. The source of truth for URLs. |
| [`PRJNA896722.samples.tsv`](PRJNA896722.samples.tsv) | 78 | Curated: each biological sample joined to its cell line, KCLB number and sample type. |
| [`SAMPLES.md`](SAMPLES.md) | 26 | Student-facing picker — one row per cell line, three linked accessions. |

`PRJNA896722.samples.tsv` columns:

```text
cell_line               SNU-4072
kclb_number             04072
sample_type             tumor | blood | cell_line
sample_alias            KCLB18MES0299     submitter's internal ID
fastq_run               SRR22272502       <- use this one
fastq_sample_accession  SAMN31563445
read_count              65522278
instrument_model        Illumina HiSeq 2500
library_name            LID_37
bam_run                 SRR22269383       <- the BAM-submitted duplicate
bam_sample_accession    SAMN31703565
```

## The 156 runs are 78 samples

This is the single most important thing to know about this BioProject, and the
thing that cost the most time when the data was first pulled.

Every biological sample was submitted **twice**:

1. once as raw paired FASTQ — the `SRR22272xxx` series, 78 runs
2. once as a recalibrated, aligned BAM (`*.recal.bam`) — the `SRR22269xxx`
   series, 78 runs

ENA generates FASTQ for both, so `fastq_ftp` is populated on all 156 rows and
the project *looks* like 156 independent runs. It is not. The two runs for a
sample carry different `run_accession` values **and different `SAMN` BioSample
accessions**, so deduplicating on accession does not help. The only field that
reveals the pairing is `sample_alias`, which holds the submitter's own sample
name plus the original filename:

```text
KCLB18MES0281.recal.bam    -> KCLB18MES0281   (BAM-submitted run)
KCLB18MES0281_1.fastq.gz   -> KCLB18MES0281   (FASTQ-submitted run)
```

Strip the filename part and 156 aliases collapse to 78:

```bash
tail -n +2 PRJNA896722.runs.tsv | cut -f14 \
  | sed 's/\.recal\.bam$//; s/_1\.fastq\.gz$//' \
  | sort | uniq -c | awk '{print $1}' | sort | uniq -c
#   78 2      every alias appears exactly twice
```

The two run types also differ in file count, which is the quickest way to tell
them apart:

| Run type | Series | Files in `fastq_ftp` |
|---|---|---|
| FASTQ-submitted | `SRR22272xxx` | 2 — `_1`, `_2` |
| BAM-submitted | `SRR22269xxx` | 3 — `_1`, `_2`, and an unsuffixed orphan file |

**Use the `SRR22272xxx` series.** It is the submitter's original data. The
`SRR22269xxx` series is the same reads after the original authors' alignment and
base recalibration, round-tripped back to FASTQ — strictly worse as pipeline
input, and it drags along an orphan file that is easy to mistake for a third
read.

## How the sample table was built

`PRJNA896722.samples.tsv` did not come out of ENA in this form. Three sources
had to be joined, because no single one of them carries both the accession and
the cell-line identity.

**1. ENA run report → accessions and aliases.** The `filereport` API gives
`run_accession`, `sample_accession`, `sample_alias`, `read_count` and the FASTQ
URLs. What it does *not* give is which cell line a sample belongs to: every
`sample_title` in this project is the useless placeholder
`Human sample from Homo sapiens`.

**2. NCBI BioSample → sample identity.** The BioSample records behind each
`SAMN` accession carry `tissue`, `cell_type` and — the useful one — `isolate`,
whose values look like `SNU-3978_5`. That is what ties an anonymous
`KCLB18MES0281` to a named cell line, and the trailing index is what
distinguishes the tumor, blood and cell-line samples of one patient.

**3. KCLB catalog and the data descriptor → cell line names and numbers.** The
26 cell-line names were cross-checked against Table 1 of the Scientific Data
descriptor and against the KCLB glioblastoma search results.

The aliases turn out to run in consecutive triples, one patient per triple:

```text
KCLB18MES0281  SNU-3978  tumor
KCLB18MES0282  SNU-3978  blood
KCLB18MES0283  SNU-3978  cell_line
KCLB18MES0284  SNU-3980  tumor
...
```

### KCLB numbers

The KCLB catalog number is the five-digit, zero-padded numeric part of the SNU
name:

```text
SNU-3978  ->  KCLB No. 03978
SNU-4116  ->  KCLB No. 04116
```

Do **not** confuse this with the `KCLB18MES0281`-style values in `sample_alias`.
Those are the study's internal sample identifiers and have nothing to do with
the KCLB catalog numbering; `KCLB18MES0281` is not catalog number 0281.

## Verification

```bash
# 78 samples, evenly split across three sample types
tail -n +2 PRJNA896722.samples.tsv | wc -l              # 78
tail -n +2 PRJNA896722.samples.tsv | cut -f3 | sort | uniq -c
#   26 blood
#   26 cell_line
#   26 tumor

# 26 cell lines, each with exactly three samples
tail -n +2 PRJNA896722.samples.tsv | cut -f1 | sort -u | wc -l   # 26
tail -n +2 PRJNA896722.samples.tsv | cut -f1 | sort | uniq -c \
  | awk '$1!=3'                                          # no output

# no duplicated runs, and every run exists in the raw report
tail -n +2 PRJNA896722.samples.tsv | cut -f5 | sort | uniq -d    # no output
comm -23 <(tail -n +2 PRJNA896722.samples.tsv | cut -f5 | sort) \
         <(tail -n +2 PRJNA896722.runs.tsv    | cut -f1 | sort)  # no output
```

## Caveats

- Tumor, blood and cell line from one patient are **matched, not replicated**.
  They are three biologically different materials. Blood is the germline
  reference; the cell line has been through selection in culture and will not
  match the tumor variant for variant.
- The KCLB links in `SAMPLES.md` are *search* URLs, not permanent record pages.
  They return current catalog results, which may change.
- `sample_title` is a placeholder for every run in this project. Do not try to
  parse it.
- The 26 tumor/blood pairs are what makes somatic calling possible here. A
  cell-line-only analysis can only do germline calling, or somatic calling
  against the patient's blood, in which case it measures tumor evolution plus
  culture adaptation together.

## Sources

- ENA BioProject: <https://www.ebi.ac.uk/ena/browser/view/PRJNA896722>
- ENA run report API:
  <https://www.ebi.ac.uk/ena/portal/api/filereport?accession=PRJNA896722&result=read_run&format=tsv&fields=run_accession,sample_alias,fastq_ftp,submitted_ftp>
- KCLB glioblastoma search:
  <https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=Glioblastoma&qt=name>
- Data descriptor, Table 1:
  <https://www.nature.com/articles/s41597-023-02365-y/tables/1>
- NCBI BioSample records for the `SAMN…` accessions in the run report.
