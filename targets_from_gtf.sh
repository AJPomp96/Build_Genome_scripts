#!/bin/bash
#SBATCH --output=./slurm-out/tgtgtf-%j.out
#SBATCH --job-name=tgts_from_gtf
#SBATCH --mem=32000
#SBATCH -c 2

#JOB LOG HEADER
perl -E 'say"="x80'; echo "JOB STARTED: `date`"; echo "NODE: `hostname`"; echo "SCRIPT ${0}:"; echo "JOB ID: ${SLURM_JOB_ID}"; cat $0; perl -E 'say"="x80'

#SOFTWARE REQUIREMENTS

#VARIABLES
TARGETS=$(pwd)/scripts/Build_Genome_scripts/Crystallin_symbols.txt
TGTLABL=gene_name
GTFPATH=$(pwd)/Mus_musculus.GRCm39.${ENSEMBL_RELEASE}.gtf
RESULTS=$(pwd)/crystallins.gtf

echo ensembl release: $ENSEMBL_RELEASE
#COMMAND(s) TO RUN
if [ ! -z $TGTLABL ] && [ ! -z $TARGETS ]
then
    gawk -v lbl=${TGTLABL}\
	 -v FS="\t| |;"\
	 '\
          # Store values from first file in an array of label target pairs
          # with the target surrounded by quotes using \042 
	  (NR == FNR)\
          {
              tgt[lbl" \042"$1"\042"];
              next
          }
          
          # For lines from second (gtf) file iterate over array of targets
          # and print the line if a match exists
          (NR != FNR)\
          {
	     for(i in tgt){
                if($0 ~ i){
	  	    print $0
	  	}
             }
          }
          ' $TARGETS $GTFPATH > ${RESULTS}
fi


#JOB LOG FOOTER
perl -E 'say"="x80'; echo "JOB COMPLETED: `date`"; perl -E 'say"="x80'
