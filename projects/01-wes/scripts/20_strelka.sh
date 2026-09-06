#!/usr/bin/env bash
#
# 20_strelka.sh - Strelka2 germline / somatic variant calling
#
# Reproduces the --tools strelka path of nf-core/sarek 3.10.0. Strelka2 replaces
# GATK HaplotypeCaller / Mutect2, which makes this far lighter and faster.
#
#   germline : call germline variants in one sample (normally the blood)
#   somatic  : call somatic variants in a tumor vs. matched normal (blood) pair
#              (if Manta is available, its candidate indels are handed to
#              Strelka, which improves indel sensitivity)
#
# Usage:
#   ./20_strelka.sh germline <SAMPLE_ID> <sample.bam>
#   ./20_strelka.sh somatic  <PAIR_ID>   <normal.bam> <tumor.bam>
#
# Example:
#   ./20_strelka.sh germline SNU-4072_blood ../results/bam/SNU-4072_blood.markdup.bam
#   ./20_strelka.sh somatic  SNU-4072 \
#       ../results/bam/SNU-4072_blood.markdup.bam \
#       ../results/bam/SNU-4072_tumor.markdup.bam
#
# Environment overrides:
#   REF           reference FASTA (uncompressed, faidx indexed)
#   OUT_DIR       output root                        (default: <project>/results)
#   THREADS       Strelka local job count            (default: nproc, max 16)
#   EXOME         1 = --exome (WES mode)             (default: 1)
#   CALL_REGIONS  target BED (bgzip + tabix)         (default: none)
#   RUN_MANTA     1 = run Manta before somatic       (default: 1 if available)
#   FORCE         1 = re-run even if output exists   (default: 0)
#
# Where Strelka / Manta live (set at most one of each; otherwise PATH is used):
#   STRELKA_BIN   bin directory of a Strelka installation
#   STRELKA_IMG   Strelka container image (singularity)
#   MANTA_BIN     bin directory of a Manta installation
#   MANTA_IMG     Manta container image (singularity)
#
# NOTE On some environments (recent glibc), the bioconda strelka 2.9.10 package
#      ships a somatic strelka2 binary that segfaults immediately. The germline
#      binary (starling2) is fine, so germline-from-conda plus
#      somatic-from-container is a workable combination. Check with:
#          <strelka>/libexec/strelka2 -h >/dev/null; echo $?    # must print 0
#
# Requires: strelka 2.9.10, bcftools; optionally manta 1.6.0, singularity
#
set -euo pipefail

# Print the header comment block above as the usage message.
usage() { awk 'NR>1 && /^#/ {sub(/^# ?/,""); print; next} NR>1 {exit}' "${BASH_SOURCE[0]}"; }

# ---------------------------------------------------------------- config ----
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

REF="${REF:-/work/class/bme282.2026/pub/gencode.50/GRCh38.primary_assembly.genome.fa}"
OUT_DIR="${OUT_DIR:-$(dirname "$SCRIPT_DIR")/results}"
THREADS="${THREADS:-$(( $(nproc) < 16 ? $(nproc) : 16 ))}"
EXOME="${EXOME:-1}"
CALL_REGIONS="${CALL_REGIONS:-}"
FORCE="${FORCE:-0}"

STRELKA_BIN="${STRELKA_BIN:-}"
STRELKA_IMG="${STRELKA_IMG:-}"
MANTA_BIN="${MANTA_BIN:-}"
MANTA_IMG="${MANTA_IMG:-}"
SINGULARITY_BINDS="${SINGULARITY_BINDS:--B /work -B /home}"

# ------------------------------------------------------- tool resolution ----
# Strelka and Manta are Python 2 workflows whose install layout varies wildly.
# If STRELKA_IMG / MANTA_IMG is set, run through singularity; else if
# STRELKA_BIN / MANTA_BIN is set, run from there; else fall back to PATH.

# shellcheck disable=SC2206
STRELKA_RUN=(); [ -n "$STRELKA_IMG" ] && STRELKA_RUN=(singularity exec $SINGULARITY_BINDS "$STRELKA_IMG")
# shellcheck disable=SC2206
MANTA_RUN=();   [ -n "$MANTA_IMG"   ] && MANTA_RUN=(singularity exec $SINGULARITY_BINDS "$MANTA_IMG")

strelka_tool() { if [ -n "$STRELKA_BIN" ]; then echo "$STRELKA_BIN/$1"; else echo "$1"; fi; }
manta_tool()   { if [ -n "$MANTA_BIN"   ]; then echo "$MANTA_BIN/$1";   else echo "$1";   fi; }

# $1 = "strelka"|"manta", $2 = command to run, $3.. = its arguments
run_tool() {
    local kind=$1; shift
    case "$kind" in
        strelka) "${STRELKA_RUN[@]}" "$@" ;;
        manta)   "${MANTA_RUN[@]}"   "$@" ;;
    esac
}

# $1 = "strelka"|"manta", $2 = tool name
has_tool() {
    local kind=$1 tool; tool=$([ "$1" = strelka ] && strelka_tool "$2" || manta_tool "$2")
    run_tool "$kind" bash -c "command -v '$tool'" >/dev/null 2>&1
}

require_tool() {
    has_tool "$1" "$2" && return 0
    cat >&2 <<MSG
[ERROR] $2 was not found, or could not be executed.

  Option 1) container (most reliable):
      singularity pull strelka.sif docker://quay.io/biocontainers/strelka:2.9.10--h9ee0642_1
      singularity pull manta.sif   docker://quay.io/biocontainers/manta:1.6.0--h9ee0642_1
      export STRELKA_IMG=\$PWD/strelka.sif
      export MANTA_IMG=\$PWD/manta.sif

  Option 2) conda:
      conda create -y -n strelka -c conda-forge -c bioconda strelka=2.9.10 manta=1.6.0
      conda activate strelka
      # If somatic calling segfaults, see the NOTE in this script's header
      # and switch to STRELKA_IMG.

  Option 3) point at an existing installation:
      export STRELKA_BIN=/path/to/strelka-2.9.10/bin
      export MANTA_BIN=/path/to/manta-1.6.0/bin
MSG
    exit 1
}

# Show the tail of the failing step's log. pyflow writes errors only to its log,
# so without this a failure looks like silence.
die_with_log() {
    local msg=$1 log=$2
    if [ -s "$log" ]; then
        echo "        ---- log (ERROR lines, truncated) ----" >&2
        { grep -oE '\[ERROR\].*' "$log" || tail -n 8 "$log"; } | cut -c1-160 | tail -n 8 >&2
    fi
    echo "[ERROR] $msg" >&2
    echo "        full log: $log" >&2
    if grep -q "python2.*No such file" "$log" 2>/dev/null; then
        echo "        HINT: Strelka and Manta need python2." >&2
        echo "              Run 'conda activate strelka', or use STRELKA_IMG / MANTA_IMG." >&2
    fi
    if grep -q 'taskExitCode -11' "$log" 2>/dev/null; then
        echo "        HINT: strelka2 died with SIGSEGV. This is most likely the bioconda build." >&2
        echo "              Use a container via STRELKA_IMG, or a working build via STRELKA_BIN" >&2
        echo "              (see the NOTE in this script's header)." >&2
    fi
    exit 1
}

# ------------------------------------------------------------- arguments ----
MODE="${1:-}"
case "$MODE" in
    germline)
        [ "$#" -eq 3 ] || { echo "[ERROR] usage: $0 germline <SAMPLE_ID> <sample.bam>" >&2; exit 1; }
        ID=$2; BAM_N=$3; BAM_T=""
        ;;
    somatic)
        [ "$#" -eq 4 ] || { echo "[ERROR] usage: $0 somatic <PAIR_ID> <normal.bam> <tumor.bam>" >&2; exit 1; }
        ID=$2; BAM_N=$3; BAM_T=$4
        ;;
    *)
        usage
        exit 1
        ;;
esac

for b in "$BAM_N" ${BAM_T:+"$BAM_T"}; do
    [ -s "$b" ]        || { echo "[ERROR] BAM not found: $b" >&2; exit 1; }
    [ -s "${b}.bai" ]  || { echo "[ERROR] BAM index not found: ${b}.bai  (samtools index $b)" >&2; exit 1; }
done
[ -s "$REF" ] && [ -s "${REF}.fai" ] || {
    echo "[ERROR] reference or index missing: $REF(.fai)  - see 10_bwa_map.sh" >&2; exit 1; }

# Strelka refuses a gzip-compressed reference.
case "$REF" in
    *.gz) echo "[ERROR] Strelka does not accept a gzipped reference. Use the uncompressed FASTA." >&2; exit 1 ;;
esac

# ----------------------------------------------------------- shared args ----
COMMON_ARGS=( --referenceFasta "$REF" )
[ "$EXOME" = "1" ] && COMMON_ARGS+=( --exome )
if [ -n "$CALL_REGIONS" ]; then
    [ -s "$CALL_REGIONS" ] && [ -s "${CALL_REGIONS}.tbi" ] || {
        echo "[ERROR] CALL_REGIONS must be a bgzip + tabix indexed BED: $CALL_REGIONS(.tbi)" >&2; exit 1; }
    COMMON_ARGS+=( --callRegions "$CALL_REGIONS" )
fi

VCF_DIR="$OUT_DIR/vcf"
LOG_DIR="$OUT_DIR/logs"
mkdir -p "$VCF_DIR" "$LOG_DIR"

echo "[INFO] mode       : $MODE"
echo "[INFO] id         : $ID"
echo "[INFO] normal BAM : $BAM_N"
[ -n "$BAM_T" ] && echo "[INFO] tumor  BAM : $BAM_T"
echo "[INFO] reference  : $REF"
echo "[INFO] exome      : $EXOME   callRegions: ${CALL_REGIONS:-none}"
echo "[INFO] threads    : $THREADS"
echo "[INFO] start      : $(date '+%F %T')"

# ============================================================== GERMLINE ====
if [ "$MODE" = "germline" ]; then
    require_tool strelka configureStrelkaGermlineWorkflow.py

    OUT_VCF="$VCF_DIR/${ID}.germline.PASS.vcf.gz"
    if [ -s "$OUT_VCF" ] && [ "$FORCE" != "1" ]; then
        echo "[SKIP] already exists: $OUT_VCF  (set FORCE=1 to re-run)"; exit 0
    fi

    RUN_DIR="$OUT_DIR/strelka/${ID}.germline"
    rm -rf "$RUN_DIR"; mkdir -p "$RUN_DIR"

    run_tool strelka "$(strelka_tool configureStrelkaGermlineWorkflow.py)" \
        --bam "$BAM_N" \
        --runDir "$RUN_DIR" \
        "${COMMON_ARGS[@]}" \
        > "$LOG_DIR/${ID}.strelka_germline.config.log" 2>&1 \
        || die_with_log "Strelka germline configuration failed" "$LOG_DIR/${ID}.strelka_germline.config.log"

    run_tool strelka "$RUN_DIR/runWorkflow.py" -m local -j "$THREADS" \
        > "$LOG_DIR/${ID}.strelka_germline.run.log" 2>&1 \
        || die_with_log "Strelka germline run failed" "$LOG_DIR/${ID}.strelka_germline.run.log"

    RAW="$RUN_DIR/results/variants/variants.vcf.gz"
    cp -f "$RAW"        "$VCF_DIR/${ID}.germline.vcf.gz"
    cp -f "${RAW}.tbi"  "$VCF_DIR/${ID}.germline.vcf.gz.tbi"

    # In practice only PASS variants go on to annotation.
    bcftools view -f PASS -O z -o "$OUT_VCF" "$RAW"
    bcftools index -t "$OUT_VCF"

    echo "[INFO] all      : $VCF_DIR/${ID}.germline.vcf.gz"
    echo "[INFO] PASS     : $OUT_VCF ($(bcftools view -H "$OUT_VCF" | wc -l) variants)"
fi

# =============================================================== SOMATIC ====
if [ "$MODE" = "somatic" ]; then
    require_tool strelka configureStrelkaSomaticWorkflow.py

    OUT_VCF="$VCF_DIR/${ID}.somatic.PASS.vcf.gz"
    if [ -s "$OUT_VCF" ] && [ "$FORCE" != "1" ]; then
        echo "[SKIP] already exists: $OUT_VCF  (set FORCE=1 to re-run)"; exit 0
    fi

    # ---- optional: hand Manta's candidate small indels to Strelka ----------
    RUN_MANTA="${RUN_MANTA:-auto}"
    if [ "$RUN_MANTA" = "auto" ]; then
        has_tool manta configManta.py && RUN_MANTA=1 || RUN_MANTA=0
    fi

    INDEL_ARGS=()
    if [ "$RUN_MANTA" = "1" ]; then
        require_tool manta configManta.py
        MANTA_DIR="$OUT_DIR/manta/${ID}"
        rm -rf "$MANTA_DIR"; mkdir -p "$MANTA_DIR"

        echo "[INFO] running Manta to generate candidate small indels..."
        run_tool manta "$(manta_tool configManta.py)" \
            --normalBam "$BAM_N" \
            --tumorBam  "$BAM_T" \
            --runDir "$MANTA_DIR" \
            "${COMMON_ARGS[@]}" \
            > "$LOG_DIR/${ID}.manta.config.log" 2>&1 \
            || die_with_log "Manta configuration failed" "$LOG_DIR/${ID}.manta.config.log"

        run_tool manta "$MANTA_DIR/runWorkflow.py" -m local -j "$THREADS" \
            > "$LOG_DIR/${ID}.manta.run.log" 2>&1 \
            || die_with_log "Manta run failed" "$LOG_DIR/${ID}.manta.run.log"

        CAND="$MANTA_DIR/results/variants/candidateSmallIndels.vcf.gz"
        [ -s "$CAND" ] && INDEL_ARGS=( --indelCandidates "$CAND" )
        cp -f "$MANTA_DIR/results/variants/somaticSV.vcf.gz"     "$VCF_DIR/${ID}.manta.somaticSV.vcf.gz"
        cp -f "$MANTA_DIR/results/variants/somaticSV.vcf.gz.tbi" "$VCF_DIR/${ID}.manta.somaticSV.vcf.gz.tbi"
    else
        echo "[WARN] running without Manta; indel sensitivity will be somewhat lower."
    fi

    # ---- Strelka somatic ---------------------------------------------------
    RUN_DIR="$OUT_DIR/strelka/${ID}.somatic"
    rm -rf "$RUN_DIR"; mkdir -p "$RUN_DIR"

    run_tool strelka "$(strelka_tool configureStrelkaSomaticWorkflow.py)" \
        --normalBam "$BAM_N" \
        --tumorBam  "$BAM_T" \
        --runDir "$RUN_DIR" \
        "${COMMON_ARGS[@]}" \
        "${INDEL_ARGS[@]+"${INDEL_ARGS[@]}"}" \
        > "$LOG_DIR/${ID}.strelka_somatic.config.log" 2>&1 \
        || die_with_log "Strelka somatic configuration failed" "$LOG_DIR/${ID}.strelka_somatic.config.log"

    run_tool strelka "$RUN_DIR/runWorkflow.py" -m local -j "$THREADS" \
        > "$LOG_DIR/${ID}.strelka_somatic.run.log" 2>&1 \
        || die_with_log "Strelka somatic run failed (taskExitCode -11 means the strelka2 binary segfaulted - see the NOTE in this script's header)" "$LOG_DIR/${ID}.strelka_somatic.run.log"

    SNV="$RUN_DIR/results/variants/somatic.snvs.vcf.gz"
    IND="$RUN_DIR/results/variants/somatic.indels.vcf.gz"
    for v in "$SNV" "$IND"; do
        cp -f "$v"       "$VCF_DIR/$(basename "${v%.vcf.gz}" | sed "s/^somatic/${ID}.somatic/").vcf.gz"
        cp -f "${v}.tbi" "$VCF_DIR/$(basename "${v%.vcf.gz}" | sed "s/^somatic/${ID}.somatic/").vcf.gz.tbi"
    done

    # Merge PASS SNVs and PASS indels into one file.
    TMP_SNV=$(mktemp -u "$VCF_DIR/.${ID}.snv.XXXX.vcf.gz")
    TMP_IND=$(mktemp -u "$VCF_DIR/.${ID}.ind.XXXX.vcf.gz")
    bcftools view -f PASS -O z -o "$TMP_SNV" "$SNV"; bcftools index -t "$TMP_SNV"
    bcftools view -f PASS -O z -o "$TMP_IND" "$IND"; bcftools index -t "$TMP_IND"
    bcftools concat -a -O z -o "$OUT_VCF" "$TMP_SNV" "$TMP_IND"
    bcftools index -t "$OUT_VCF"
    rm -f "$TMP_SNV" "$TMP_SNV.tbi" "$TMP_IND" "$TMP_IND.tbi"

    echo "[INFO] SNV      : $VCF_DIR/${ID}.somatic.snvs.vcf.gz   ($(bcftools view -H -f PASS "$SNV" | wc -l) PASS)"
    echo "[INFO] INDEL    : $VCF_DIR/${ID}.somatic.indels.vcf.gz ($(bcftools view -H -f PASS "$IND" | wc -l) PASS)"
    echo "[INFO] merged   : $OUT_VCF"
fi

echo "[INFO] done       : $(date '+%F %T')"
