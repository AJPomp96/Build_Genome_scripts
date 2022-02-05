#!/bin/bash
#SBATCH --output=./slurm-out/genannot-%j.out
#SBATCH --job-name=genMmAnnot
#SBATCH --mem=8000
#SBATCH -c 1

#JOB LOG HEADER
perl -E 'say"="x80'; echo "JOB STARTED: `date`"; echo "NODE: `hostname`"; echo "SCRIPT ${0}:"; echo "JOB ID: ${SLURM_JOB_ID}"; cat $0; perl -E 'say"="x80'

#SOFTWARE REQUIREMENTS

#VARIABLES
export PATH=$PATH:$(pwd)/scripts/Build_Genome_scripts/

#COMMAND(s) TO RUN
echo $ENSEMBL_RELEASE

Rscript --vanilla $(pwd)/scripts/Build_Genome_scripts/gen_EnsMm_annot.R ${ENSEMBL_RELEASE} ${wd}

#JOB LOG FOOTER
perl -E 'say"="x80'; echo "JOB COMPLETED: `date`"; perl -E 'say"="x80'
