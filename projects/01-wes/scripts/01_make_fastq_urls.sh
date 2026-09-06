#!/usr/bin/env bash
#
# 01_make_fastq_urls.sh - turn an ENA run report into a list of FASTQ URLs
#
# Emits only the paired _1 / _2 files. Unsuffixed orphan files (present on
# BAM-derived runs) are dropped: they are not a third read of the pair.
#
# Usage:
#   ./01_make_fastq_urls.sh <runs.tsv> [runs_to_keep.txt] > urls.txt
#
#   runs.tsv           ENA run report from 00_fetch_ena_metadata.sh
#   runs_to_keep.txt   optional; one run accession per line. Without it, every
#                      run in the report is included - which for PRJNA896722
#                      means 699 GB, most of it duplicated. Always pass a list.
#
# Example:
#   cut -f5 ../metadata/samples.six.tsv | tail -n +2 > keep.txt
#   ./01_make_fastq_urls.sh ../../../data/PRJNA896722/PRJNA896722.runs.tsv keep.txt > urls.txt
#
set -euo pipefail

usage() { awk 'NR>1 && /^#/ {sub(/^# ?/,""); print; next} NR>1 {exit}' "${BASH_SOURCE[0]}"; }

RUNS="${1:-}"
KEEP="${2:-}"

[ -s "${RUNS:-/nonexistent}" ] || { usage; exit 1; }

# Column 1 is run_accession, column 12 is fastq_ftp (';'-separated).
# tail -n +2 drops the header - without it the header cell 'fastq_ftp' would
# become a URL of its own.
tail -n +2 "$RUNS" \
| awk -F'\t' -v keep="$KEEP" '
    BEGIN {
        if (keep != "") { while ((getline r < keep) > 0) if (r != "") want[r]=1 }
    }
    keep != "" && !($1 in want) { next }
    {
        n = split($12, f, ";")
        for (i = 1; i <= n; i++) if (f[i] ~ /_[12]\.fastq\.gz$/) print "https://" f[i]
    }
' \
| sort -u
