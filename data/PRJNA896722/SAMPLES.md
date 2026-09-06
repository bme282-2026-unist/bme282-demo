# PRJNA896722 — sample picker

Pick one cell line from the table below. Each row gives you three matched
exomes from the same patient: the tumor tissue, the patient's blood, and the
cell line established from that tumor.

- **tumor** — tumor tissue taken from the patient
- **blood** — matched normal from the same patient; this is the germline
  reference for somatic variant calling
- **cell_line** — the patient-derived cell line grown from that tumor

For project 1 you need **tumor + blood** at minimum. Add **cell_line** if you
want to ask what changed when the tumor was put into culture.

## Before you download anything

Six of these cell lines are **already on the class server** and need no
download at all — they are marked in the `on server` column:

```text
/work/class/bme282.2026/pub/PRJNA896722/six/
```

All 156 runs are also on the server under `.../PRJNA896722/total/`. Check there
before fetching anything from ENA; see [`README.md`](README.md) and
[`../../docs/02-shared-data.md`](../../docs/02-shared-data.md).

If you do need to download from ENA, follow
[`../../docs/03-ena-downloads.md`](../../docs/03-ena-downloads.md). The short
version:

```bash
SRR=SRR22272502
grep -P "^$SRR\t" PRJNA896722.runs.tsv | cut -f12 | tr ';' '\n' \
  | grep -E '_[12]\.fastq\.gz$' | sed 's|^|https://|' \
  | xargs -n1 wget -c
```

Take the URLs from [`PRJNA896722.runs.tsv`](PRJNA896722.runs.tsv) rather than
building them by hand — the numeric subdirectory in an ENA path
(`.../SRR222/002/SRR22272502/`) is a zero-padded slice of the accession, and
guessing it wrong is the most common way to get a 404. Clicking the accession in
the table below and using the `FASTQ files` section of the ENA run page works
just as well.

## What you get per run

Each of the accessions below is paired-end, and gives you exactly two files:

```text
SRR22272502_1.fastq.gz   # R1
SRR22272502_2.fastq.gz   # R2
```

Use both together. If you see a third file with no `_1`/`_2` suffix on an ENA
page, it holds orphan reads — ignore it. See
[`../../docs/03-ena-downloads.md`](../../docs/03-ena-downloads.md#3-single-end-paired-end-and-the-third-file).

Runs are 30–150 million read pairs, 3–8 GB per file.

## Sample list

26 cell lines × 3 sample types = 78 exomes.

| KCLB No. | Cell line | on server | Tumor | Blood | Cell line | KCLB page |
|---:|---|:-:|---|---|---|---|
| 03978 | SNU-3978 |  | [SRR22272553](https://www.ebi.ac.uk/ena/browser/view/SRR22272553) | [SRR22272521](https://www.ebi.ac.uk/ena/browser/view/SRR22272521) | [SRR22272510](https://www.ebi.ac.uk/ena/browser/view/SRR22272510) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-3978&qt=name) |
| 03980 | SNU-3980 |  | [SRR22272499](https://www.ebi.ac.uk/ena/browser/view/SRR22272499) | [SRR22272487](https://www.ebi.ac.uk/ena/browser/view/SRR22272487) | [SRR22272552](https://www.ebi.ac.uk/ena/browser/view/SRR22272552) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-3980&qt=name) |
| 03987 | SNU-3987 | yes | [SRR22272538](https://www.ebi.ac.uk/ena/browser/view/SRR22272538) | [SRR22272532](https://www.ebi.ac.uk/ena/browser/view/SRR22272532) | [SRR22272512](https://www.ebi.ac.uk/ena/browser/view/SRR22272512) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-3987&qt=name) |
| 04026 | SNU-4026 |  | [SRR22272511](https://www.ebi.ac.uk/ena/browser/view/SRR22272511) | [SRR22272520](https://www.ebi.ac.uk/ena/browser/view/SRR22272520) | [SRR22272519](https://www.ebi.ac.uk/ena/browser/view/SRR22272519) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-4026&qt=name) |
| 04054 | SNU-4054 | yes | [SRR22272518](https://www.ebi.ac.uk/ena/browser/view/SRR22272518) | [SRR22272517](https://www.ebi.ac.uk/ena/browser/view/SRR22272517) | [SRR22272516](https://www.ebi.ac.uk/ena/browser/view/SRR22272516) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-4054&qt=name) |
| 04071 | SNU-4071 | yes | [SRR22272515](https://www.ebi.ac.uk/ena/browser/view/SRR22272515) | [SRR22272514](https://www.ebi.ac.uk/ena/browser/view/SRR22272514) | [SRR22272513](https://www.ebi.ac.uk/ena/browser/view/SRR22272513) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-4071&qt=name) |
| 04072 | SNU-4072 | yes | [SRR22272502](https://www.ebi.ac.uk/ena/browser/view/SRR22272502) | [SRR22272501](https://www.ebi.ac.uk/ena/browser/view/SRR22272501) | [SRR22272509](https://www.ebi.ac.uk/ena/browser/view/SRR22272509) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-4072&qt=name) |
| 04098 | SNU-4098 | yes | [SRR22272508](https://www.ebi.ac.uk/ena/browser/view/SRR22272508) | [SRR22272507](https://www.ebi.ac.uk/ena/browser/view/SRR22272507) | [SRR22272506](https://www.ebi.ac.uk/ena/browser/view/SRR22272506) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-4098&qt=name) |
| 04116 | SNU-4116 |  | [SRR22272505](https://www.ebi.ac.uk/ena/browser/view/SRR22272505) | [SRR22272504](https://www.ebi.ac.uk/ena/browser/view/SRR22272504) | [SRR22272503](https://www.ebi.ac.uk/ena/browser/view/SRR22272503) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-4116&qt=name) |
| 04137 | SNU-4137 |  | [SRR22272491](https://www.ebi.ac.uk/ena/browser/view/SRR22272491) | [SRR22272490](https://www.ebi.ac.uk/ena/browser/view/SRR22272490) | [SRR22272489](https://www.ebi.ac.uk/ena/browser/view/SRR22272489) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-4137&qt=name) |
| 04138 | SNU-4138 |  | [SRR22272498](https://www.ebi.ac.uk/ena/browser/view/SRR22272498) | [SRR22272497](https://www.ebi.ac.uk/ena/browser/view/SRR22272497) | [SRR22272496](https://www.ebi.ac.uk/ena/browser/view/SRR22272496) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-4138&qt=name) |
| 04177 | SNU-4177 |  | [SRR22272495](https://www.ebi.ac.uk/ena/browser/view/SRR22272495) | [SRR22272494](https://www.ebi.ac.uk/ena/browser/view/SRR22272494) | [SRR22272493](https://www.ebi.ac.uk/ena/browser/view/SRR22272493) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-4177&qt=name) |
| 04210 | SNU-4210 |  | [SRR22272492](https://www.ebi.ac.uk/ena/browser/view/SRR22272492) | [SRR22272479](https://www.ebi.ac.uk/ena/browser/view/SRR22272479) | [SRR22272477](https://www.ebi.ac.uk/ena/browser/view/SRR22272477) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-4210&qt=name) |
| 04254 | SNU-4254 |  | [SRR22272500](https://www.ebi.ac.uk/ena/browser/view/SRR22272500) | [SRR22272486](https://www.ebi.ac.uk/ena/browser/view/SRR22272486) | [SRR22272485](https://www.ebi.ac.uk/ena/browser/view/SRR22272485) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-4254&qt=name) |
| 04312 | SNU-4312 |  | [SRR22272484](https://www.ebi.ac.uk/ena/browser/view/SRR22272484) | [SRR22272482](https://www.ebi.ac.uk/ena/browser/view/SRR22272482) | [SRR22272483](https://www.ebi.ac.uk/ena/browser/view/SRR22272483) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-4312&qt=name) |
| 04327 | SNU-4327 |  | [SRR22272481](https://www.ebi.ac.uk/ena/browser/view/SRR22272481) | [SRR22272480](https://www.ebi.ac.uk/ena/browser/view/SRR22272480) | [SRR22272476](https://www.ebi.ac.uk/ena/browser/view/SRR22272476) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-4327&qt=name) |
| 04484 | SNU-4484 |  | [SRR22272478](https://www.ebi.ac.uk/ena/browser/view/SRR22272478) | [SRR22272488](https://www.ebi.ac.uk/ena/browser/view/SRR22272488) | [SRR22272551](https://www.ebi.ac.uk/ena/browser/view/SRR22272551) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-4484&qt=name) |
| 04514 | SNU-4514 |  | [SRR22272550](https://www.ebi.ac.uk/ena/browser/view/SRR22272550) | [SRR22272548](https://www.ebi.ac.uk/ena/browser/view/SRR22272548) | [SRR22272549](https://www.ebi.ac.uk/ena/browser/view/SRR22272549) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-4514&qt=name) |
| 04546 | SNU-4546 |  | [SRR22272545](https://www.ebi.ac.uk/ena/browser/view/SRR22272545) | [SRR22272546](https://www.ebi.ac.uk/ena/browser/view/SRR22272546) | [SRR22272543](https://www.ebi.ac.uk/ena/browser/view/SRR22272543) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-4546&qt=name) |
| 04638 | SNU-4638 |  | [SRR22272547](https://www.ebi.ac.uk/ena/browser/view/SRR22272547) | [SRR22272536](https://www.ebi.ac.uk/ena/browser/view/SRR22272536) | [SRR22272537](https://www.ebi.ac.uk/ena/browser/view/SRR22272537) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-4638&qt=name) |
| 04689 | SNU-4689 |  | [SRR22272539](https://www.ebi.ac.uk/ena/browser/view/SRR22272539) | [SRR22272540](https://www.ebi.ac.uk/ena/browser/view/SRR22272540) | [SRR22272541](https://www.ebi.ac.uk/ena/browser/view/SRR22272541) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-4689&qt=name) |
| 04702 | SNU-4702 |  | [SRR22272542](https://www.ebi.ac.uk/ena/browser/view/SRR22272542) | [SRR22272544](https://www.ebi.ac.uk/ena/browser/view/SRR22272544) | [SRR22272535](https://www.ebi.ac.uk/ena/browser/view/SRR22272535) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-4702&qt=name) |
| 04954 | SNU-4954 |  | [SRR22272534](https://www.ebi.ac.uk/ena/browser/view/SRR22272534) | [SRR22272533](https://www.ebi.ac.uk/ena/browser/view/SRR22272533) | [SRR22272523](https://www.ebi.ac.uk/ena/browser/view/SRR22272523) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-4954&qt=name) |
| 04982 | SNU-4982 |  | [SRR22272522](https://www.ebi.ac.uk/ena/browser/view/SRR22272522) | [SRR22272531](https://www.ebi.ac.uk/ena/browser/view/SRR22272531) | [SRR22272530](https://www.ebi.ac.uk/ena/browser/view/SRR22272530) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-4982&qt=name) |
| 05026 | SNU-5026 | yes | [SRR22272529](https://www.ebi.ac.uk/ena/browser/view/SRR22272529) | [SRR22272528](https://www.ebi.ac.uk/ena/browser/view/SRR22272528) | [SRR22272527](https://www.ebi.ac.uk/ena/browser/view/SRR22272527) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-5026&qt=name) |
| 05262 | SNU-5262 |  | [SRR22272526](https://www.ebi.ac.uk/ena/browser/view/SRR22272526) | [SRR22272525](https://www.ebi.ac.uk/ena/browser/view/SRR22272525) | [SRR22272524](https://www.ebi.ac.uk/ena/browser/view/SRR22272524) | [KCLB](https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=SNU-5262&qt=name) |

The accessions above are the **FASTQ-submitted** runs (`SRR22272xxx`). The same
78 samples also appear in ENA as BAM-submitted runs (`SRR22269xxx`) — do not use
those; see [`README.md`](README.md#the-156-runs-are-78-samples).

The full table with BioSample accessions, read counts and the corresponding
BAM-submitted runs is in
[`PRJNA896722.samples.tsv`](PRJNA896722.samples.tsv).

## Recording your choice

Write your selection into your own `metadata/samples.tsv` before you start, and
use the sample ID everywhere afterwards — in the read group, the BAM name, and
the VCF:

```tsv
sample_id	sample_type	cell_line	run	r1	r2
SNU-4072_tumor	tumor	SNU-4072	SRR22272502	/work/class/bme282.2026/pub/PRJNA896722/six/SRR22272502_1.fastq.gz	/work/class/bme282.2026/pub/PRJNA896722/six/SRR22272502_2.fastq.gz
SNU-4072_blood	blood	SNU-4072	SRR22272501	/work/class/bme282.2026/pub/PRJNA896722/six/SRR22272501_1.fastq.gz	/work/class/bme282.2026/pub/PRJNA896722/six/SRR22272501_2.fastq.gz
```

## Sources

- ENA BioProject: <https://www.ebi.ac.uk/ena/browser/view/PRJNA896722>
- KCLB glioblastoma search:
  <https://cellbank.snu.ac.kr/cellline/search?listheight=50&sc=y&q=Glioblastoma&qt=name>
- Data descriptor with cell-line list and clinical information:
  <https://www.nature.com/articles/s41597-023-02365-y> (Table 1)
