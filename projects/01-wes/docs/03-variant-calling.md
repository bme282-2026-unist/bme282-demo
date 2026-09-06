# 03 — Alignment and variant calling

**Produces:** analysis-ready BAMs and germline / somatic VCFs, via
[`../scripts/10_bwa_map.sh`](../scripts/10_bwa_map.sh) and
[`../scripts/20_strelka.sh`](../scripts/20_strelka.sh).

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

| Script | Role | sarek equivalent |
|---|---|---|
| `10_bwa_map.sh` | FASTQ → analysis-ready BAM | `fastp` → `bwa mem` → `markduplicates` |
| `20_strelka.sh` | BAM → VCF (germline / somatic) | `--tools strelka` (+ `manta`) |

## Differences from sarek

This is [nf-core/sarek 3.10.0](https://nf-co.re/sarek/3.10.0/) reduced to two
shell scripts. Three deliberate departures:

- **BQSR (base quality score recalibration) is skipped.** Strelka2, unlike GATK,
  does not assume recalibrated base qualities. Dropping it also removes the need
  to download the known-sites VCFs (dbSNP, Mills, …), which is several more
  gigabytes of reference data for no benefit here.
- **MarkDuplicates is `samtools markdup`, not GATK/picard.** Same result, one
  fewer Java dependency.
- **No Nextflow.** For a handful of samples, plain shell is easier to read, to
  debug, and to teach from. The cost is that nothing is parallelized across
  samples for you.

The alignment itself is not simplified: `bwa mem -K 100000000 -Y` is exactly
what sarek uses. `-K` fixes the input chunk size so results do not depend on the
thread count, and `-Y` soft-clips supplementary alignments.

## Prerequisites

### 1. Reference index — once, by the instructor

Strelka accepts only an **uncompressed** FASTA, so the shared `.fa.gz` has to be
expanded and indexed. This takes 1–1.5 hours and about 8 GB, and it has already
been done in `pub/` — do not repeat it in your own directory.

```bash
REF_GZ=/work/class/bme282.2026/pub/gencode.50/GRCh38.primary_assembly.genome.fa.gz
REF=/work/class/bme282.2026/pub/gencode.50/GRCh38.primary_assembly.genome.fa

zcat "$REF_GZ" > "$REF"
samtools faidx "$REF"      # -> .fai   (required by Strelka)
bwa index "$REF"           # -> .bwt etc. (required by bwa; the slow part)
```

### 2. Tools

```bash
conda create -y -n bme282-wes -c conda-forge -c bioconda \
    bwa samtools bcftools fastp multiqc
conda create -y -n strelka -c conda-forge -c bioconda \
    strelka=2.9.10 manta=1.6.0
```

After installing, **verify that the somatic binary actually runs**:

```bash
conda activate strelka
"$CONDA_PREFIX"/share/strelka-2.9.10-*/libexec/strelka2 -h >/dev/null; echo $?
# must print 0
```

### 3. Optional — exome target BED

WES has no reason to call outside the capture regions. If you have the capture
kit's BED, supply it. (`--exome` is on by default via `EXOME=1`; the BED is a
separate thing.)

```bash
sort -k1,1 -k2,2n targets.bed | bgzip > targets.bed.gz
tabix -p bed targets.bed.gz
export CALL_REGIONS=$PWD/targets.bed.gz
```

## Running it

SNU-4072 (KCLB 04072): tumor `SRR22272502`, blood `SRR22272501`. Any other row
of [`../../../data/PRJNA896722/SAMPLES.md`](../../../data/PRJNA896722/SAMPLES.md)
works the same way.

```bash
cd projects/01-wes/scripts
export REF=/work/class/bme282.2026/pub/gencode.50/GRCh38.primary_assembly.genome.fa
export OUT_DIR=~/bme282.2026/$USER/project01/results
PUB=/work/class/bme282.2026/pub/PRJNA896722/six

# (1) mapping - about 2-4 hours per sample on 16 cores
./10_bwa_map.sh SNU-4072_blood $PUB/SRR22272501_1.fastq.gz $PUB/SRR22272501_2.fastq.gz
./10_bwa_map.sh SNU-4072_tumor $PUB/SRR22272502_1.fastq.gz $PUB/SRR22272502_2.fastq.gz

# (2) variant calling
conda activate strelka
export STRELKA_IMG=$PWD/strelka.sif        # see the known issue below

./20_strelka.sh germline SNU-4072_blood $OUT_DIR/bam/SNU-4072_blood.markdup.bam

./20_strelka.sh somatic  SNU-4072 \
    $OUT_DIR/bam/SNU-4072_blood.markdup.bam \
    $OUT_DIR/bam/SNU-4072_tumor.markdup.bam
```

Both scripts skip work whose output already exists. `FORCE=1` re-runs it.

## Environment variables

| Variable | Default | Meaning |
|---|---|---|
| `REF` | GRCh38 in `pub/gencode.50` | uncompressed FASTA, `faidx` + `bwa index`ed |
| `OUT_DIR` | `<project>/results` | output root — point this at your own directory |
| `THREADS` | `nproc`, capped at 16 | bwa mem / Strelka parallelism |
| `SORT_MEM` | `2G` | samtools sort memory per thread (`SORT_THREADS`×`SORT_MEM` ≤ RAM) |
| `TRIM` | `1` | fastp adapter trimming |
| `EXOME` | `1` | Strelka `--exome` — leave on for WES |
| `CALL_REGIONS` | none | bgzip + tabix indexed target BED |
| `RUN_MANTA` | auto | use Manta candidate indels in somatic mode |
| `STRELKA_IMG` / `MANTA_IMG` | none | singularity images |
| `STRELKA_BIN` / `MANTA_BIN` | none | bin directories of existing installs |
| `FORCE` | `0` | ignore existing output and re-run |

## Known issue: bioconda strelka2 segfaults

On this server (Ubuntu, glibc 2.39, kernel 6.8) the bioconda `strelka2` binary
**dies with SIGSEGV the moment it is executed**. The failure is in the loader,
so even `strelka2 -h` fails. The germline binary (`starling2`) and Manta are
both fine.

In other words: **germline calling works from conda, somatic calling does not.**

In a pipeline run it shows up as `taskExitCode -11` buried in the pyflow log;
`20_strelka.sh` detects that and says so rather than leaving you to find it.

The workaround is to run Strelka from a container and keep using conda for
everything else:

```bash
singularity pull strelka.sif docker://quay.io/biocontainers/strelka:2.9.10--h9ee0642_1
export STRELKA_IMG=$PWD/strelka.sif      # Strelka from the container
conda activate strelka                   # Manta stays as installed
```

Or, if you already have a working build from source:

```bash
export STRELKA_BIN=/path/to/strelka-2.9.10/bin
```

**Status:** the container workaround is documented but has not yet been run to
completion on this server. Somatic calling for the six teaching samples is the
next thing to do in this project.

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

## What to check

Mapping QC, before you call anything:

```bash
cat $OUT_DIR/qc/SNU-4072_tumor/SNU-4072_tumor.flagstat.txt
grep -E '^SN\s+(raw total sequences|reads mapped:|reads duplicated)' \
    $OUT_DIR/qc/SNU-4072_tumor/SNU-4072_tumor.stats.txt
```

Expect >95% mapped for a healthy exome. A high duplicate rate means a
low-complexity library, and it caps how much depth you can actually use.

Variant counts:

```bash
bcftools view -H $OUT_DIR/vcf/SNU-4072.somatic.PASS.vcf.gz | wc -l
```

Somatic VCFs from Strelka carry **no `GT` and no `AF` field** — this surprises
everyone the first time. Allele fraction has to be computed from the tier-1
counts: for SNVs, the first value of `FORMAT/{A,C,G,T}U`.

```bash
bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\t%INFO/SomaticEVS\n' \
    $OUT_DIR/vcf/SNU-4072.somatic.PASS.vcf.gz | head
```

`SomaticEVS` is Strelka's empirical variant score; higher is more confident.

## References

- nf-core/sarek 3.10.0: <https://nf-co.re/sarek/3.10.0/>
- Strelka2 user guide: <https://github.com/Illumina/strelka/blob/v2.9.x/docs/userGuide/README.md>
- Manta user guide: <https://github.com/Illumina/manta/blob/master/docs/userGuide/README.md>
- Sample list: [`../../../data/PRJNA896722/SAMPLES.md`](../../../data/PRJNA896722/SAMPLES.md)
