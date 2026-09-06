#!/usr/bin/env bash
#
# 00_fetch_ena_metadata.sh - download the ENA run report for a BioProject
#
# Writes <ACCESSION>.runs.tsv: one row per sequencing run, with the FASTQ URLs
# and the metadata needed to work out which biological sample each run is.
#
# Usage:
#   ./00_fetch_ena_metadata.sh [ACCESSION] [OUTPUT.tsv]
#
# Example:
#   ./00_fetch_ena_metadata.sh PRJNA896722 ../../../data/PRJNA896722/PRJNA896722.runs.tsv
#
# Requires: curl
#
# Field list: https://www.ebi.ac.uk/ena/portal/api/returnFields?result=read_run
#
set -euo pipefail

usage() { awk 'NR>1 && /^#/ {sub(/^# ?/,""); print; next} NR>1 {exit}' "${BASH_SOURCE[0]}"; }
case "${1:-}" in -h|--help) usage; exit 0 ;; esac

ACC="${1:-PRJNA896722}"
OUT="${2:-${ACC}.runs.tsv}"

FIELDS="run_accession,study_accession,sample_accession,experiment_accession"
FIELDS="$FIELDS,tax_id,scientific_name,instrument_model,library_name"
FIELDS="$FIELDS,library_strategy,library_source,read_count"
FIELDS="$FIELDS,fastq_ftp,submitted_ftp,sample_alias,sample_title,bam_ftp"

URL="https://www.ebi.ac.uk/ena/portal/api/filereport"
URL="$URL?accession=${ACC}&result=read_run&format=tsv&fields=${FIELDS}"

echo "[INFO] accession : $ACC"
echo "[INFO] output    : $OUT"

curl -fsSL "$URL" -o "$OUT"

n=$(( $(wc -l < "$OUT") - 1 ))
[ "$n" -gt 0 ] || { echo "[ERROR] empty run report - check the accession" >&2; exit 1; }

echo "[INFO] runs      : $n"
echo
echo "[INFO] files per run (2 = clean pair, 3 = pair + orphan file):"
awk -F'\t' 'NR>1 {n=split($12,a,";"); print n}' "$OUT" | sort | uniq -c

echo
echo "[INFO] distinct sample aliases (runs may double-count samples):"
tail -n +2 "$OUT" | cut -f14 \
    | sed 's/\.recal\.bam$//; s/_1\.fastq\.gz$//; s/_1\.fq\.gz$//' \
    | sort -u | wc -l
