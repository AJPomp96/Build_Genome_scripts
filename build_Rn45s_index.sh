#!/bin/bash
#SBATCH --output=./slurm-out/rn45indx-%j.out
#SBATCH --job-name=build_Rn45s_index
#SBATCH --mem=32000
#SBATCH -c 1

#JOB LOG HEADER
perl -E 'say"="x80'; echo "JOB STARTED: `date`"; echo "NODE: `hostname`"; echo "SCRIPT ${0}:"; echo "JOB ID: ${SLURM_JOB_ID}"; cat $0; perl -E 'say"="x80'

#SOFTWARE REQUIREMENTS

#VARIABLES


#COMMAND(s) TO RUN
esearch -db nucleotide -query "NR_046233.2" | efetch -format fasta > $(pwd)/Rn45s.fasta

hisat2-build -f -p 8 Rn45s.fasta RNA45SN5_Index

#JOB LOG FOOTER
perl -E 'say"="x80'; echo "JOB COMPLETED: `date`"; perl -E 'say"="x80'
