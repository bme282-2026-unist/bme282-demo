# Server setup

Everything in this course runs on the class Linux server. Nothing needs to be
installed on your laptop except an SSH client and, optionally, a Git client.

## Machine

| | |
|---|---|
| OS | Ubuntu (Linux kernel 6.8) |
| CPU | 16 cores |
| RAM | 31 GB |
| Class storage | `/work/class/bme282.2026/` on a 19 TB volume |

16 cores and 31 GB of RAM is enough for one exome sample at a time. It is not
enough for four students to run `bwa index` simultaneously — coordinate before
launching anything that runs for hours.

## Directory layout

```text
/work/class/bme282.2026/
├── pub/          read-only shared data (see docs/02-shared-data.md)
├── home/
├── taejoon/      instructor working directory (this repo lives here)
└── <username>/   your working directory
```

Your home directory also has a shortcut to the same tree:

```bash
ls ~/bme282.2026/
```

`~/bme282.2026/<username>` and `/work/class/bme282.2026/<username>` are the same
files. Use whichever you find easier to type.

## Rules of the road

1. **Never write into `pub/`.** It is shared, it is large, and re-downloading
   699 GB from ENA takes days.
2. **Never copy FASTQ files into your working directory.** Reference them by
   their path under `pub/`, or symlink them:
   ```bash
   ln -s /work/class/bme282.2026/pub/PRJNA896722/six/SRR22272502_1.fastq.gz .
   ```
3. **Check free space before you start.** A single exome BAM is 5–15 GB.
   ```bash
   df -h /work/class
   du -sh /work/class/bme282.2026/$USER
   ```
4. **Long jobs must survive your logout.** Use `nohup` or `tmux`:
   ```bash
   nohup ./01_bwa_map.sh SNU-4072_tumor R1.fastq.gz R2.fastq.gz > map.log 2>&1 &
   tail -f map.log
   ```

## Software

Bioinformatics tools are installed through conda. Create one environment per
project rather than one giant environment — the variant callers in project 1
still depend on Python 2 and will fight with anything modern.

```bash
# project 1: alignment + variant calling
conda create -y -n bme282-wes -c conda-forge -c bioconda \
    bwa samtools bcftools fastp multiqc
conda create -y -n strelka -c conda-forge -c bioconda \
    strelka=2.9.10 manta=1.6.0
```

Check what a script needs before you run it; each script in this repository
lists its dependencies in its header comment.

### Containers

Some tools do not run correctly from conda on this kernel (see the known issue
with `strelka2` in
[`../projects/01-wes/docs/03-variant-calling.md`](../projects/01-wes/docs/03-variant-calling.md)).
When that happens, pull a container instead:

```bash
singularity pull strelka.sif docker://quay.io/biocontainers/strelka:2.9.10--h9ee0642_1
```

## Git

This repository is public:
<https://github.com/bme282-2026-unist/bme282-demo>

```bash
git clone https://github.com/bme282-2026-unist/bme282-demo.git
```

Set your identity once, in your own repository:

```bash
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
```

Commit scripts, notes and small metadata tables. Do not commit FASTQ, BAM, VCF
or count matrices — the [`.gitignore`](../.gitignore) in this repository is a
reasonable starting point to copy.
