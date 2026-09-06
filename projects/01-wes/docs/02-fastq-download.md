# 02 — FASTQ download

**Produces:** the staged FASTQ under
`/work/class/bme282.2026/pub/PRJNA896722/`, 312 files in `total/` (699 GB) and
36 in `six/` (88 GB).

This is a record of how the shared data got there, including two attempts that
downloaded the wrong things. Students do not need to repeat any of it — the
data is already on the server. Read it for the general recipe in
[`../../../docs/03-ena-downloads.md`](../../../docs/03-ena-downloads.md), and
for the specific mistakes worth not repeating.

## How to run it

```bash
cd projects/01-wes/scripts

# 1. run report from ENA
./00_fetch_ena_metadata.sh PRJNA896722 ../../../data/PRJNA896722/PRJNA896722.runs.tsv

# 2. decide which runs you want, and turn them into URLs
tail -n +2 ../metadata/samples.six.tsv | cut -f5 > keep.txt
./01_make_fastq_urls.sh ../../../data/PRJNA896722/PRJNA896722.runs.tsv keep.txt > urls.txt
wc -l urls.txt          # 36

# 3. download
nohup ./02_download_fastq.sh urls.txt /work/class/bme282.2026/pub/PRJNA896722/six \
    > download.log 2>&1 &
tail -f download.log
```

Step 2 is the one that matters. `01_make_fastq_urls.sh` without a keep-list
emits 312 URLs for the whole project; with the six-cell-line list it emits 36.

## What actually happened

### The first pass — 390 URLs, unfiltered

The first download script was generated straight from the ENA run report with a
`cut` and a `sed`, with no filtering at all: `wget.sh` with 314 lines, plus a
follow-up `wget2.sh` with 78 more for the `_2` files the first pass had missed.
Together, 390 URLs — every file ENA lists for all 156 runs.

Two separate bugs, both visible in the first two lines of the generated script:

```bash
wget ftp://fastq_ftp
wget ftp://
```

**The header row became a URL.** `cut -f12` on the unskipped header yields the
literal string `fastq_ftp`. Harmless here, but a clear sign the list was
generated without anyone reading it.

**Orphan files were included.** Filtering on `_1`/`_2` gives 312 URLs for the
whole project. Without that filter you get 390:

```bash
tail -n +2 PRJNA896722.runs.tsv | cut -f12 | tr ';' '\n' | sort -u | wc -l
# 390
tail -n +2 PRJNA896722.runs.tsv | cut -f12 | tr ';' '\n' \
  | grep -cE '_[12]\.fastq\.gz$'
# 312
```

The extra 78 are the unsuffixed orphan files attached to the BAM-derived runs.
They came down as `SRR22269xxx.fastq.gz`, 12 GB of mate-less reads with no
`_1`/`_2` counterpart. They look like data. They are not usable as paired input,
and they were discarded.

This pass took two days and did, in the end, fetch the whole project. The 312
proper pairs from it are what now sits in
`/work/class/bme282.2026/pub/PRJNA896722/total/`. Note that this includes both
run types — the BAM-derived `SRR22269xxx` pairs are there too, so the
duplicate-run question can be examined directly rather than taken on faith. For
analysis, use the `SRR22272xxx` accessions listed in
[`../metadata/samples.all.tsv`](../metadata/samples.all.tsv).

Getting the right files by accident, after downloading 12 GB of the wrong ones
and spending two days at it, is not the same as getting them on purpose.

### The second pass — the six-cell-line subset

Once [`01-sample-selection.md`](01-sample-selection.md) had resolved which runs
were which, six complete tumor/blood/cell-line triples were selected and fetched
with a script that filtered properly and skipped what was already present:

```bash
download_if_missing() {
    local url="$1" file="${url##*/}"
    if [ -s "$file" ]; then printf 'SKIP %s\n' "$file"
    else printf 'GET  %s\n' "$file"; wget -c "$url"; fi
}
```

36 files, 88 GB, under six hours at 2.5–5.5 MB/s. That is
`/work/class/bme282.2026/pub/PRJNA896722/six/`, and it is the set the pipeline
was developed against.

The scripts in [`../scripts/`](../scripts/) are the generalized version of this
second pass — the run report, the keep-list, the filter, and the resumable
download, in four steps instead of one hand-written file.

## Verification

```bash
cd /work/class/bme282.2026/pub/PRJNA896722

ls six | wc -l                                  # 36
ls total | wc -l                                # 312
find . -name '*.fastq.gz' -size 0               # empty
ls total | sed 's/^SRR[0-9]*//' | sort | uniq -c
#  156 _1.fastq.gz
#  156 _2.fastq.gz
```

Every path in `../metadata/samples.six.tsv` and `../metadata/samples.all.tsv`
was checked to exist and be non-empty.

The URL list regenerates reproducibly — running `01_make_fastq_urls.sh` against
the six-sample keep-list and comparing to what is on disk gives no differences:

```bash
comm -3 <(sed 's|.*/||' urls.txt | sort) <(ls six | sort)   # empty
```

## Lessons

1. **Resolve the sample identities before generating URLs, not after.** Every
   problem above traces back to downloading first and asking what the files
   were second.
2. **`tail -n +2`.** A header row silently becomes a data row in every shell
   pipeline that touches a TSV.
3. **Filter to `_1`/`_2` explicitly.** Never assume a run has exactly two FASTQ
   files.
4. **Make the download re-runnable from the start.** `wget -c` plus an
   `[ -s "$file" ]` check turns a failed six-hour transfer into a five-second
   restart.
5. **Keep the download log.** `nohup.out` is the only durable record of what was
   transferred and when.
