# Project 1 — Whole-exome sequencing of GBM cell lines

Take a glioblastoma patient-derived cell line, its parent tumor and the
patient's blood; align all three exomes to GRCh38; call germline variants
against the blood and somatic variants in the tumor/blood pair; and end up with
a short list of variants worth taking to the bench in project 2.

**Status:** data downloaded and staged on the server; alignment and
variant-calling scripts written and documented. Somatic calling is blocked on a
tooling issue that has a documented workaround — see
[`docs/03-variant-calling.md`](docs/03-variant-calling.md#known-issue-bioconda-strelka2-segfaults).

## Data

[PRJNA896722](https://www.ebi.ac.uk/ena/browser/view/PRJNA896722) — 26 GBM
patient-derived cell lines from the Korean Cell Line Bank, each with matched
tumor tissue and blood. 78 exomes in total.

Everything is already on the server; **you do not need to download anything**:

```text
/work/class/bme282.2026/pub/PRJNA896722/six/     6 cell lines x 3 samples  (88 GB)
/work/class/bme282.2026/pub/PRJNA896722/total/   all 78 samples           (699 GB)
```

Full description: [`../../data/PRJNA896722/README.md`](../../data/PRJNA896722/README.md).
Sample picker: [`../../data/PRJNA896722/SAMPLES.md`](../../data/PRJNA896722/SAMPLES.md).

## Contents

```text
01-wes/
├── docs/
│   ├── 01-sample-selection.md   how the 78 runs were resolved to 26 cell lines
│   ├── 02-fastq-download.md     what was downloaded, what went wrong, what was kept
│   └── 03-variant-calling.md    the sarek-equivalent pipeline, and where it breaks
├── metadata/
│   ├── samples.six.tsv          18 samples, the teaching subset (pub/six)
│   └── samples.all.tsv          all 78 samples (pub/total)
└── scripts/
    ├── 00_fetch_ena_metadata.sh   ENA BioProject -> run report TSV
    ├── 01_make_fastq_urls.sh      run report -> filtered FASTQ URL list
    ├── 02_download_fastq.sh       URL list -> FASTQ files (resumable)
    ├── 10_bwa_map.sh              FASTQ -> analysis-ready BAM
    └── 20_strelka.sh              BAM -> germline / somatic VCF
```

Scripts 00–02 are how the shared data got onto the server. They are here so the
process is reproducible, not because you need to run them.

## Pipeline

```text
FASTQ (R1/R2)
   │  10_bwa_map.sh
   ├─ fastp            adapter trimming + read QC
   ├─ bwa mem -K 100000000 -Y
   ├─ samtools fixmate → sort → markdup
   └─ *.markdup.bam (+ .bai)
        │  20_strelka.sh
        ├─ germline : blood BAM               → Strelka germline → *.germline.PASS.vcf.gz
        └─ somatic  : blood + tumor BAM pair  → (Manta) → Strelka somatic
                                              → *.somatic.PASS.vcf.gz
```

This is [nf-core/sarek 3.10.0](https://nf-co.re/sarek/3.10.0/)'s germline and
somatic paths, reproduced with `bwa` + `samtools` + `Strelka2` and no GATK. See
[`docs/03-variant-calling.md`](docs/03-variant-calling.md#differences-from-sarek)
for what was deliberately left out and why.

## Walkthrough — SNU-4072

One cell line, start to finish. Tumor `SRR22272502`, blood `SRR22272501`.

### 0. Set up

```bash
conda activate bme282-wes          # bwa, samtools, bcftools, fastp
cd projects/01-wes/scripts

export REF=/work/class/bme282.2026/pub/gencode.50/GRCh38.primary_assembly.genome.fa
export OUT_DIR=~/bme282.2026/$USER/project01/results
PUB=/work/class/bme282.2026/pub/PRJNA896722/six
```

Point `OUT_DIR` at your own directory. The default writes into this repository,
which is fine for the instructor and wrong for everyone else.

### 1. Map — about 2–4 hours per sample on 16 cores

```bash
nohup bash -c "
  ./10_bwa_map.sh SNU-4072_blood $PUB/SRR22272501_1.fastq.gz $PUB/SRR22272501_2.fastq.gz
  ./10_bwa_map.sh SNU-4072_tumor $PUB/SRR22272502_1.fastq.gz $PUB/SRR22272502_2.fastq.gz
" > map.log 2>&1 &

tail -f map.log
```

Check before going further — a run with 60% mapped reads is not worth calling
variants on:

```bash
cat $OUT_DIR/qc/SNU-4072_tumor/SNU-4072_tumor.flagstat.txt
```

### 2. Call variants

```bash
conda activate strelka
export STRELKA_IMG=$PWD/strelka.sif        # see the known issue in docs/03

./20_strelka.sh germline SNU-4072_blood $OUT_DIR/bam/SNU-4072_blood.markdup.bam

./20_strelka.sh somatic  SNU-4072 \
    $OUT_DIR/bam/SNU-4072_blood.markdup.bam \
    $OUT_DIR/bam/SNU-4072_tumor.markdup.bam
```

Both scripts skip work that is already done. Set `FORCE=1` to redo it.

### 3. Look at the results

```bash
bcftools view -H $OUT_DIR/vcf/SNU-4072.somatic.PASS.vcf.gz | wc -l

bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\t%INFO/SomaticEVS\n' \
    $OUT_DIR/vcf/SNU-4072.somatic.PASS.vcf.gz | head
```

## Running a whole batch

The sample sheets in `metadata/` are built for this:

```bash
tail -n +2 ../metadata/samples.six.tsv | while IFS=$'\t' read -r sid cl kclb stype run r1 r2; do
    ./10_bwa_map.sh "$sid" "$r1" "$r2"
done
```

18 samples at 2–4 hours each is 2–3 days of wall clock on this machine. Plan
accordingly, and do not launch it in parallel with three classmates doing the
same thing.

## Output layout

```text
$OUT_DIR/
├── bam/    SNU-4072_blood.markdup.bam (+ .bai)
├── vcf/    SNU-4072_blood.germline.vcf.gz         all calls, filters included
│           SNU-4072_blood.germline.PASS.vcf.gz    PASS only
│           SNU-4072.somatic.snvs.vcf.gz
│           SNU-4072.somatic.indels.vcf.gz
│           SNU-4072.somatic.PASS.vcf.gz           PASS SNVs + indels, merged
│           SNU-4072.manta.somaticSV.vcf.gz        structural variants (if Manta ran)
├── qc/     fastp html/json, flagstat, samtools stats, markdup stats
├── logs/   per-step logs — start here when something fails
└── strelka/, manta/                               workflow scratch directories
```

## Feeding project 2

Project 2 amplifies a handful of these variants by PCR and re-sequences them.
Candidates worth carrying forward are PASS somatic variants that are (a) in a
gene with a known role in GBM, (b) supported by enough reads that a Sanger trace
will show them, and (c) in a region a primer pair can actually be designed
against. Export them as a small BED or TSV into
[`../02-targeted-seq/metadata/`](../02-targeted-seq/metadata/).

## References

- nf-core/sarek 3.10.0: <https://nf-co.re/sarek/3.10.0/>
- Strelka2 user guide: <https://github.com/Illumina/strelka/blob/v2.9.x/docs/userGuide/README.md>
- Manta user guide: <https://github.com/Illumina/manta/blob/master/docs/userGuide/README.md>
- bwa: <https://github.com/lh3/bwa>
- samtools / bcftools: <https://www.htslib.org/doc/>
