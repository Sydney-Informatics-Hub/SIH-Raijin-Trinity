#!/bin/bash

# This will launch trinity for all samples listed in a fastq.list file.
# Trinity is run 5 parts

# Set variables
project=<project>
io=/short/${project}
script=${io}/Scripts
list=${io}/<samples>.list
seqtype=fq

# normalbw
cpu_per_node=28
nodes_used=10
# express queue - for testing
#cpu_per_node=16    # mem requested MUST be set to a multiple of this number
#nodes_used=2 # must be total nodes used in trinity_4.pbs 64($PBS_NCPUS/$cpu_per_node))

num_pairs=$(grep -c -v '^$' ${list})

# Loop through each line of fastq.list, and submit all trinity jobs. Trinity 2-5 will only start
# when the previous part has run successfully
for i in $(seq 1 ${num_pairs}); do
	# Extracts "tissue" name from filename - change to suit your samples
	tissue=$(basename -- "$(awk -v taskID=1 '$1=taskID {print $2}' all_samples.list)") | cut -d _ -f 1
    out=${io}/trinity/${tissue}
    echo `date` ": STARTING TRINITY FOR ${tissue}"
    # trinity_1.pbs
    echo `date` ": Launching Trinity Part 1"
    first=$(qsub \
    -v input="${i}",seqtype="${seqtype}",io="${io}",out="${out}",list="${list}",tissue="${tissue}",mem="256G" \
    -N ${tissue}_1 \
    -P ${project} \
    -l wd,ncpus=24,mem=256GB,walltime=02:00:00,jobfs=250GB \
    -q normalbw \
    ${script}/trinity_1.pbs)

    # trinity_2.pbs
    echo `date` ": Launching Trinity Part 2"
    second=$(qsub \
    -W depend=afterok:${first} \
    -v input="${i}",seqtype="${seqtype}",io="${io}",out="${out}",list="${list}",tissue="${tissue}",mem="128G" \
    -N ${tissue}_2 \
    -P ${project} \
    -l wd,ncpus=24,mem=128GB,walltime=03:00:00,jobfs=100GB \
    -q normalbw \
    ${script}/trinity_2.pbs)

    # trinity_3.pbs
    echo `date` ": Launching Trinity Part 3"
    third=$(qsub \
    -W depend=afterok:${second} \
    -v input="${i}",seqtype="${seqtype}",io="${io}",out="${out}",list="${list}",tissue="${tissue}",mem="128G" \
    -N ${tissue}_3 \
    -P ${project} \
    -l wd,ncpus=24,mem=128GB,walltime=18:00:00,jobfs=400GB \
    -q normalbw \
    ${script}/trinity_3.pbs)

    # trinity_4.pbs
    echo `date` ": Launching Trinity Part 4"
    fourth=$(qsub \
    -W depend=afterok:${third} \
    -v input="${i}",seqtype="${seqtype}",io="${io}",out="${out}",list="${list}",tissue="${tissue}",mem="4G",cpu_per_node="${cpu_per_node}" \
    -N ${tissue}_4 \
    -P ${project} \
    -l wd,ncpus=280,mem=1120GB,walltime=24:00:00,jobfs=3500GB \
    -q normalbw \
    ${script}/trinity_4.pbs)
    
    # trinity_5.pbs
    echo `date` ": Launching Trinity Part 5"
    qsub \
    -W depend=afterok:${fourth} \
    -v input="${i}",seqtype="${seqtype}",io="${io}",out="${out}",list="${list}",tissue="${tissue}",cpu_per_node="${cpu_per_node}",nodes_used="${nodes_used}" \
    -N ${tissue}_5 \
    -P ${project} \
    -l wd,ncpus=1,mem=32GB,walltime=10:00:00,jobfs=400GB \
    -q copyq \
    ${script}/trinity_5.pbs 
done
