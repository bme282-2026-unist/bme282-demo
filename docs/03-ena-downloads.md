# Downloading public sequencing data from ENA

The European Nucleotide Archive (ENA) mirrors everything in NCBI's SRA and
serves it as plain FASTQ over HTTPS and FTP. No `sratoolkit`, no `fasterq-dump`,
no accession-key setup — just a URL and `wget`.

This document is the general recipe. For what was actually done for project 1,
see [`../projects/01-wes/docs/02-fastq-download.md`](../projects/01-wes/docs/02-fastq-download.md).

## 1. Get the run report

Every BioProject has a browsable page:

<https://www.ebi.ac.uk/ena/browser/view/PRJNA896722>

and a machine-readable run report behind the `filereport` API. Ask for the
fields you need, as TSV:

```bash
ACC=PRJNA896722
curl -s "https://www.ebi.ac.uk/ena/portal/api/filereport\
?accession=${ACC}\
&result=read_run\
&format=tsv\
&fields=run_accession,study_accession,sample_accession,experiment_accession,\
tax_id,scientific_name,instrument_model,library_name,library_strategy,\
library_source,read_count,fastq_ftp,fastq_md5,submitted_ftp,sample_alias,\
sample_title,bam_ftp" \
  > ${ACC}.runs.tsv

wc -l ${ACC}.runs.tsv
```

Useful fields:

| Field | Why you want it |
|---|---|
| `run_accession` | the `SRR…` ID |
| `sample_accession` | the `SAMN…` BioSample — the *biological* sample |
| `sample_alias` | the submitter's own name for the sample, often the only place the real sample identity survives |
| `library_strategy` | `WXS`, `RNA-Seq`, `AMPLICON`, … |
| `read_count` | how big this run is, before you download it |
| `fastq_ftp` | `;`-separated list of FASTQ URLs |
| `fastq_md5` | `;`-separated checksums, in the same order |
| `submitted_ftp` | what the submitter uploaded (may be BAM) |

Full field list: <https://www.ebi.ac.uk/ena/portal/api/returnFields?result=read_run>

## 2. Read the table before downloading anything

This is the step that is always skipped and always costs the most time. Three
things to check:

**How many runs, and are they really distinct samples?** A study that submits
both FASTQ and aligned BAM for every sample appears in ENA as *two runs per
sample*. Downloading all of them doubles your transfer for no extra data.

```bash
tail -n +2 PRJNA896722.runs.tsv | cut -f1 | wc -l      # 156 runs
tail -n +2 PRJNA896722.runs.tsv | cut -f14 \
  | sed 's/\.recal\.bam$//; s/_1\.fastq\.gz$//' | sort -u | wc -l   # 78 samples
```

**How many files does each run have?** Paired-end runs normally have two. Some
have three.

```bash
awk -F'\t' 'NR>1 {n=split($12,a,";"); print n}' PRJNA896722.runs.tsv \
  | sort | uniq -c
#   78 2      <- FASTQ-submitted runs: a clean pair
#   78 3      <- BAM-submitted runs: pair + orphans
```

**How much data is this?** `read_count` × read length × 2, roughly, before
compression. For PRJNA896722 the whole project is 699 GB.

## 3. Single-end, paired-end, and the third file

A **single-end** run sequences each fragment from one end only, and produces one
FASTQ file. A **paired-end** run sequences both ends of the same fragment,
producing two files whose *n*-th records are the two ends of the same molecule:

```text
SRR22272502_1.fastq.gz   # R1, forward read
SRR22272502_2.fastq.gz   # R2, reverse read
```

R1 and R2 must stay in the same order and be given to the aligner together.
Knowing that two reads came from opposite ends of one fragment, a roughly fixed
distance apart, is what lets an aligner place reads in repetitive regions,
detect structural variants, and mark PCR duplicates. That information is lost
if you align the two files separately.

Some ENA runs have a **third file with no suffix**:

```text
SRR22269317.fastq.gz     # <- orphans, NOT a third read
SRR22269317_1.fastq.gz
SRR22269317_2.fastq.gz
```

That file holds reads whose mate was dropped during submission or conversion —
typically because the submitter uploaded a BAM and ENA converted it back to
FASTQ. It is *not* single-end data and *not* a third read of the pair.

**Rule: if `_1` and `_2` exist, use exactly those two and ignore the unsuffixed
file.** In PRJNA896722, every run with three files is a BAM-derived duplicate of
a sample that already has a clean pair elsewhere in the table.

## 4. Build the URL list

Explode `fastq_ftp` on `;`, keep only `_1`/`_2`, and prefix the protocol. ENA
serves the same paths over both FTP and HTTPS; HTTPS is generally faster and
gets through firewalls that block FTP.

```bash
tail -n +2 PRJNA896722.runs.tsv \
  | cut -f12 \
  | tr ';' '\n' \
  | grep -E '_[12]\.fastq\.gz$' \
  | sed 's|^|https://|' \
  | sort -u > urls.txt

wc -l urls.txt        # 312
```

Two mistakes that this pipeline avoids, both of which were made on the first
attempt at project 1:

- **Including the header row.** `cut -f12` on the header line yields the literal
  string `fastq_ftp`, and the generated script then dutifully runs
  `wget ftp://fastq_ftp`. `tail -n +2` is not optional.
- **Not filtering on `_1`/`_2`.** Every unsuffixed orphan file gets downloaded
  too: 390 URLs instead of 312.

And the mistake this pipeline does *not* avoid, because no amount of shell can:
filter the table down to the samples you actually want **before** generating
URLs. Join against a curated sample sheet. Do not download the whole project and
sort it out afterwards.

## 5. Download

```bash
#!/usr/bin/env bash
set -u
while read -r url; do
    f=${url##*/}
    if [ -s "$f" ]; then
        printf 'SKIP %s\n' "$f"
    else
        printf 'GET  %s\n' "$f"
        wget -c "$url"
    fi
done < urls.txt
```

- `wget -c` resumes a partial file instead of restarting it. Multi-gigabyte
  transfers from Europe *will* be interrupted.
- The `-s` check makes the script re-runnable: run it again after a failure and
  it picks up where it stopped instead of re-fetching what is already on disk.
- Run it detached, and keep the log — it is the only record of what was
  actually transferred:
  ```bash
  nohup ./download.sh > download.log 2>&1 &
  tail -f download.log
  ```
- Expect roughly 3–5 MB/s to ENA from here. 88 GB is most of a day; 699 GB is
  several.

## 6. Verify

Never start an alignment on a truncated FASTQ.

```bash
# nothing empty
find . -name '*.fastq.gz' -size 0

# every archive is intact (slow, but worth doing once)
for f in *.fastq.gz; do gzip -t "$f" || echo "CORRUPT $f"; done

# R1 and R2 have the same number of reads
for f in *_1.fastq.gz; do
    n1=$(zcat "$f"         | wc -l)
    n2=$(zcat "${f/_1/_2}" | wc -l)
    echo "${f%_1.fastq.gz}  $((n1/4))  $((n2/4))"
done
```

If you requested `fastq_md5` in step 1, compare against it — that is the only
check that catches silent corruption rather than truncation.

## References

- ENA browser: <https://www.ebi.ac.uk/ena/browser/home>
- ENA Portal API: <https://www.ebi.ac.uk/ena/portal/api/>
- File-report field list: <https://www.ebi.ac.uk/ena/portal/api/returnFields?result=read_run>
