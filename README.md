# SIH-Raijin-Trinity

## Authors

* Tracy Chew (Sydney Informatics Hub, University of Sydney)
* Andrey Bliznyuk (National Computational Infrastructure)
* Rika Kobayashi (National Computational Infrastructure)

Please acknowledge us and show your support!

Suggested acknowledgement: "The authors acknowledge the scientific and/or technical assistance of Tracy Chew of the Sydney Informatics Hub at the University of Sydney and use of the National Computational Infrastructure facility."


## Background

[Trinity](https://github.com/trinityrnaseq/trinityrnaseq/wiki) assembles Illumina RNA-Seq data into transcript sequences. Trinity was developed at the Broad Institute and the Hebrew University of Jerusalem. 

SIH-Raijin-Trinity allows Trinity to be scalable by enabling use of multiple nodes on NCI Raijin. The entire workflow can complete ~4X faster using 10 broadwell nodes!

## Set up

### Software requirements

The following software needs to be installed and loadable as modules:

        samtools/1.9
        java/jdk1.8.0_60
        bowtie2/2.3.3.1
        jellyfish/2.2.6
        salmon/0.11.0
        perl/5.22.1
        trinity/2.8.4
        python3/3.6.7


### Input

A plain text file containing a list of input fastq files is used as input into trinity_phases.sh. Each row corresponds to 1 sample. There are 3 columns, column 1 = incremental number (for job array), column 2 = read 1, column 3 = read 2. 

A __fastq.list__ file can be easily created by:

        cd myFastqDir
        find $PWD -type f | sort -V | xargs -n 2 | cat -n > fastq.list


## Quick guide

Once you have set the variables (project, list, seqtype) in __trinity_phases.sh__, simply run the workflow by:

        sh trinity_phases.sh

### Overview

`trinity_phases.sh` runs trinity in 5 phases. Each phase is launched as an independent pbs script. This enhances compute efficiency by requesting only what is required for each part of the workflow (vanilla trinity requires [different amounts of compute resources throughout the entire workflow](http://trinityrnaseq.github.io/performance/cpu.html))

1. trinity_1.pbs: This script performs k-mer counting with Jellyfish and is relatively fast. Stop before Inchworm step.

2. trinity_2.pbs: Perform inchworm, stop before Chrysalis step.

3. trinity_3.pbs: Perform Chrysalis, step before parallel assembly of clustered reads.

4. trinity_4.pbs: Assemble clusters of reads using Inchworm, Chrysalis and Butterfly into transcripts. This step takes the longest, but contains many independent jobs that have been parallelized using GNU parallel. 

5. trinity_5.pbs: Harvest all assembled transcripts from trinity_4 into a single multi-fasta file.


