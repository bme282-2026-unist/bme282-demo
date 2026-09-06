#!/usr/bin/env bash
#
# 10_bwa_map.sh - FASTQ -> analysis-ready BAM
#
# Reproduces the mapping stage of nf-core/sarek 3.10.0
# (fastp -> bwa mem -> markduplicates) with bwa and samtools only, no GATK.
#
# Difference from sarek: BQSR (base quality score recalibration) is skipped.
# Strelka2, unlike GATK, does not assume recalibrated base qualities, so for an
# exome analysis it can be left out - which also removes the need to download
# the known-sites VCFs (dbSNP, Mills, ...).
#
# Usage:
#   ./10_bwa_map.sh <SAMPLE_ID> <R1.fastq.gz> <R2.fastq.gz>
#
# Example:
#   PUB=/work/class/bme282.2026/pub/PRJNA896722/six
#   ./10_bwa_map.sh SNU-4072_blood $PUB/SRR22272501_1.fastq.gz $PUB/SRR22272501_2.fastq.gz
#
# Environment overrides:
#   REF          reference FASTA (uncompressed, bwa + faidx indexed)
#   OUT_DIR      output root                       (default: <project>/results)
#   THREADS      bwa mem threads                   (default: nproc, max 16)
#   SORT_THREADS samtools sort threads             (default: 4)
#   SORT_MEM     samtools sort memory per thread   (default: 2G)
#   TRIM         1 = fastp adapter trimming on     (default: 1)
#   FORCE        1 = re-run even if output exists  (default: 0)
#
# Requires: bwa, samtools (>= 1.10), fastp
#
set -euo pipefail

# Print the header comment block above as the usage message.
usage() { awk 'NR>1 && /^#/ {sub(/^# ?/,""); print; next} NR>1 {exit}' "${BASH_SOURCE[0]}"; }

# ---------------------------------------------------------------- config ----
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

REF="${REF:-/work/class/bme282.2026/pub/gencode.50/GRCh38.primary_assembly.genome.fa}"
OUT_DIR="${OUT_DIR:-$(dirname "$SCRIPT_DIR")/results}"
THREADS="${THREADS:-$(( $(nproc) < 16 ? $(nproc) : 16 ))}"
SORT_THREADS="${SORT_THREADS:-4}"
SORT_MEM="${SORT_MEM:-2G}"
TRIM="${TRIM:-1}"
FORCE="${FORCE:-0}"
PLATFORM="${PLATFORM:-ILLUMINA}"

# ------------------------------------------------------------- arguments ----
if [ "$#" -ne 3 ]; then
    usage
    exit 1
fi

SM=$1          # sample id, e.g. SNU-4072_blood
R1=$2
R2=$3

for f in "$R1" "$R2"; do
    [ -s "$f" ] || { echo "[ERROR] FASTQ not found: $f" >&2; exit 1; }
done
if [ "$R1" = "$R2" ]; then
    echo "[ERROR] R1 and R2 are the same file. Pass the _1 and _2 files separately." >&2
    exit 1
fi

# ------------------------------------------------------- reference check ----
if [ ! -s "$REF" ] || [ ! -s "${REF}.fai" ] || [ ! -s "${REF}.bwt" ]; then
    cat >&2 <<MSG
[ERROR] The reference is not prepared: $REF
        (needed: ${REF}, ${REF}.fai, ${REF}.bwt)

  Run this once, in the shared pub directory - not in your own
  (bwa index takes 1-1.5 hours and about 8 GB):

    REF_GZ=/work/class/bme282.2026/pub/gencode.50/GRCh38.primary_assembly.genome.fa.gz
    zcat "\$REF_GZ" > "$REF"
    samtools faidx "$REF"
    bwa index "$REF"
MSG
    exit 1
fi

# ----------------------------------------------------------------- setup ----
BAM_DIR="$OUT_DIR/bam"
QC_DIR="$OUT_DIR/qc/$SM"
LOG_DIR="$OUT_DIR/logs"
TMP_DIR="$OUT_DIR/tmp/$SM"
mkdir -p "$BAM_DIR" "$QC_DIR" "$LOG_DIR" "$TMP_DIR"

BAM="$BAM_DIR/${SM}.markdup.bam"

if [ -s "$BAM" ] && [ -s "${BAM}.bai" ] && [ "$FORCE" != "1" ]; then
    echo "[SKIP] already exists: $BAM  (set FORCE=1 to re-run)"
    exit 0
fi

# Read group. Strelka and everything downstream identify the sample by the SM
# tag, so this is where the sample name enters the analysis for good.
RG="@RG\tID:${SM}\tSM:${SM}\tLB:${SM}\tPL:${PLATFORM}\tPU:${SM}"

echo "[INFO] sample     : $SM"
echo "[INFO] R1/R2      : $R1"
echo "[INFO]              $R2"
echo "[INFO] reference  : $REF"
echo "[INFO] output     : $BAM"
echo "[INFO] threads    : bwa=$THREADS sort=$SORT_THREADS x $SORT_MEM  trim=$TRIM"
echo "[INFO] start      : $(date '+%F %T')"

# ------------------------------------------------------------- alignment ----
# fastp -> bwa mem -> fixmate -> sort -> markdup, connected by pipes so that no
# intermediate FASTQ or BAM ever touches the disk (tens of GB saved per exome).
#
# bwa mem options:
#   -K 100000000  fixed input chunk size, so results do not depend on thread
#                 count - the same setting sarek uses for reproducibility
#   -Y            soft-clip supplementary alignments (sarek default)
{
    if [ "$TRIM" = "1" ]; then
        # --stdout writes interleaved FASTQ for paired input, which bwa mem -p reads
        fastp \
            --in1 "$R1" --in2 "$R2" \
            --stdout \
            --thread 4 \
            --detect_adapter_for_pe \
            --json "$QC_DIR/${SM}.fastp.json" \
            --html "$QC_DIR/${SM}.fastp.html" \
            2> "$LOG_DIR/${SM}.fastp.log" \
        | bwa mem -t "$THREADS" -K 100000000 -Y -p -R "$RG" "$REF" - \
            2> "$LOG_DIR/${SM}.bwa.log"
    else
        bwa mem -t "$THREADS" -K 100000000 -Y -R "$RG" "$REF" "$R1" "$R2" \
            2> "$LOG_DIR/${SM}.bwa.log"
    fi
} \
| samtools fixmate -m -u -@ 2 - - \
| samtools sort -u -@ "$SORT_THREADS" -m "$SORT_MEM" -T "$TMP_DIR/sort" - \
| samtools markdup -@ 2 -f "$QC_DIR/${SM}.markdup.stats" - "$BAM"

samtools index -@ "$SORT_THREADS" "$BAM"

# -------------------------------------------------------------------- QC ----
samtools flagstat -@ 4 "$BAM" > "$QC_DIR/${SM}.flagstat.txt"
samtools stats    -@ 4 "$BAM" > "$QC_DIR/${SM}.stats.txt"

rm -rf "$TMP_DIR"

echo "[INFO] done       : $(date '+%F %T')"
echo "[INFO] BAM        : $BAM"
echo "[INFO] QC         : $QC_DIR"
grep -E '^(SN\s+(raw total sequences|reads mapped:|reads duplicated))' \
    "$QC_DIR/${SM}.stats.txt" || true
