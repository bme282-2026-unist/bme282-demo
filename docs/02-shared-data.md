# Shared data on the class server

Everything below lives under `/work/class/bme282.2026/pub/` and is **read-only**
for students. It is already downloaded; do not fetch it again.

```bash
ls /work/class/bme282.2026/pub/
```

## Reference genome and annotation

`/work/class/bme282.2026/pub/gencode.50/`

| File | Size | Contents |
|---|---:|---|
| `GRCh38.primary_assembly.genome.fa.gz` | 806 MB | GRCh38 primary assembly, gzip-compressed |
| `gencode.v50.primary_assembly.annotation.gtf.gz` | 119 MB | GENCODE v50 gene annotation, GTF |
| `gencode.v50.primary_assembly.annotation.gff3.gz` | 153 MB | the same annotation, GFF3 |

Source: <https://www.gencodegenes.org/human/>

### Indexing the reference

The FASTA is stored compressed. Aligners and variant callers need it
uncompressed and indexed, and some of them (Strelka2 among them) refuse a
gzip-compressed FASTA outright.

Indexing is done **once**, by the instructor, into a shared location — it takes
about 1–1.5 hours and roughly 8 GB. Do not run it in your own directory.

```bash
REF_GZ=/work/class/bme282.2026/pub/gencode.50/GRCh38.primary_assembly.genome.fa.gz
REF=/work/class/bme282.2026/pub/gencode.50/GRCh38.primary_assembly.genome.fa

zcat "$REF_GZ" > "$REF"
samtools faidx "$REF"    # -> .fai, required by Strelka and by IGV
bwa index "$REF"         # -> .amb .ann .bwt .pac .sa, the slow one
```

Confirm the index exists before starting an alignment:

```bash
ls -la /work/class/bme282.2026/pub/gencode.50/GRCh38.primary_assembly.genome.fa*
```

## PRJNA896722 — GBM WES FASTQ

`/work/class/bme282.2026/pub/PRJNA896722/`

Whole-exome sequencing of 26 GBM patient-derived cell lines from the Korean
Cell Line Bank, with matched tumor tissue and blood for each. See
[`../data/PRJNA896722/README.md`](../data/PRJNA896722/README.md) for the full
description and [`../data/PRJNA896722/SAMPLES.md`](../data/PRJNA896722/SAMPLES.md)
for the sample table.

| Directory | Files | Size | Contents |
|---|---:|---:|---|
| `total/` | 312 | 699 GB | All 156 ENA runs, paired `_1`/`_2` FASTQ |
| `six/` | 36 | 88 GB | Teaching subset: 6 cell lines × 3 sample types × 2 files |

### `six/` — the teaching subset

Six cell lines, each with matched tumor, blood and cell-line exomes. This is
the set the demo pipeline was developed against, and the one to use unless you
have a reason not to.

| Cell line | KCLB No. | Tumor | Blood | Cell line |
|---|---:|---|---|---|
| SNU-3987 | 03987 | SRR22272538 | SRR22272532 | SRR22272512 |
| SNU-4054 | 04054 | SRR22272518 | SRR22272517 | SRR22272516 |
| SNU-4071 | 04071 | SRR22272515 | SRR22272514 | SRR22272513 |
| SNU-4072 | 04072 | SRR22272502 | SRR22272501 | SRR22272509 |
| SNU-4098 | 04098 | SRR22272508 | SRR22272507 | SRR22272506 |
| SNU-5026 | 05026 | SRR22272529 | SRR22272528 | SRR22272527 |

Per-run size ranges from 3.2 GB to 8.2 GB for the pair.

### `total/` — everything

All 156 runs. Note that the 156 runs correspond to only **78 biological
samples**: the study submitted each sample twice, once as FASTQ and once as a
recalibrated BAM, and ENA generated FASTQ from both. Use the FASTQ-submitted
run (the `SRR22272xxx` series). See
[`../data/PRJNA896722/README.md`](../data/PRJNA896722/README.md#the-156-runs-are-78-samples)
for why this matters.

## Using shared data without copying it

Symlink, or pass the path directly. Copying 88 GB into your own directory
wastes the disk and gains you nothing.

```bash
mkdir -p ~/bme282.2026/$USER/project01/fastq
cd ~/bme282.2026/$USER/project01/fastq
ln -s /work/class/bme282.2026/pub/PRJNA896722/six/SRR22272502_?.fastq.gz .
ls -lL          # -L follows the link, so you see the real sizes
```

## Adding to the shared data

If you need something that is not here — another BioProject, another reference
build, an annotation database — ask the instructor rather than downloading it
into your own directory. It is very likely someone else needs it too.
