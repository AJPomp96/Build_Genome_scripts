#!/bin/bash
#SBATCH --output=./slurm-out/dexseq-%j.out
#SBATCH --job-name=dexseq_prep
#SBATCH --mem=32000
#SBATCH -c 1

#JOB LOG HEADER
perl -E 'say"="x80'; echo "JOB STARTED: `date`"; echo "NODE: `hostname`"; echo "SCRIPT ${0}:"; echo "JOB ID: ${SLURM_JOB_ID}"; cat $0; perl -E 'say"="x80'

#SOFTWARE REQUIREMENTS

echo esembl release: $ENSEMBL_RELEASE
#VARIABLES


#COMMAND(s) TO RUN
python3 dexseq_prepare_annotation.py Mus_musculus.GRCm39.${ENSEMBL_RELEASE}.gtf EnsMm_${ENSEMBL_RELEASE}_DEXSeq_Annot.gff

#JOB LOG FOOTER
perl -E 'say"="x80'; echo "JOB COMPLETED: `date`"; perl -E 'say"="x80'
