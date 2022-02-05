#!/bin/bash
#SBATCH --output=./slurm-out/main-%j.out
#SBATCH --job-name=buildGenomePipeline
#SBATCH --mem=32000
#SBATCH -c 1

#JOB LOG HEADER
perl -E 'say"="x80'; echo "JOB STARTED: `date`"; echo "NODE: `hostname`"; echo "SCRIPT ${0}:"; echo "JOB ID: ${SLURM_JOB_ID}"; cat $0; perl -E 'say"="x80'

#SOFTWARE REQUIREMENTS

#VARIABLES
export PATH=$PATH:$(pwd)/scripts/Build_Genome_scripts
export ENSEMBL_RELEASE=105
export wd=$(pwd)

#COMMAND(s) TO RUN
echo path: $PATH
echo ensembl release: ${ENSEMBL_RELEASE}
echo wd: $wd

#build hisat index step
bhiJB=$(sbatch build_hisat_index.sh | gawk '{print $4}')

#ensembl extract eu pl length gc step
ensJB=$(sbatch --dependency=afterok:$bhiJB ensembl_extract_eu_pl_length_gc.sh | gawk '{print $4}')

#generate mouse ensembl annotation table step
genmmJB=$(sbatch --dependency=afterok:$ensJB gen_annot.sh | gawk '{print $4}')

#build hisat index for Rn45s
brnhiJB=$(sbatch --dependency=afterok:$ensJB build_Rn45s_index.sh | gawk '{print $4}')

#make rseqc bed file
rsqbedJB=$(sbatch --dependency=afterok:$ensJB ensembl_make_rseqc_bedfile.sh | gawk '{print $4}')

#targets from gtf
tgtJB=$(sbatch --dependency=afterok:$ensJB targets_from_gtf.sh | gawk '{print $4}')

#make rseqc crystallins bed file
rsqcryJB=$(sbatch --dependency=afterok:$tgtJB ensembl_make_rseqc_crys_bedfile.sh | gawk '{print $4}')

#make kallisto indices
kalindxJB=$(sbatch --dependency=afterok:$tgtJB make_kallisto_indices.sh | gawk '{print $4}')

#dexseq annotation
dxprepJB=$(sbatch --dependency=afterok:$bhiJB run_dexseq_annotation_prep.sh | gawk '{print $4}')


#JOB LOG FOOTER
perl -E 'say"="x80'; echo "JOB COMPLETED: `date`"; perl -E 'say"="x80'
