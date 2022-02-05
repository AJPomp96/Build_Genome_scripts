#!/bin/bash
#SBATCH --output=./slurm-out/rseqcbed-%j.out
#SBATCH --job-name=RSeQC_bedfile
#SBATCH --mem=32000
#SBATCH -c 2

#JOB LOG HEADER
perl -E 'say"="x80'; echo "JOB STARTED: `date`"; echo "NODE: `hostname`"; echo "SCRIPT ${0}:"; echo "JOB ID: ${SLURM_JOB_ID}"; cat $0; perl -E 'say"="x80'

#SOFTWARE REQUIREMENTS

#VARIABLES
GTFPATH=$(pwd)/Mus_musculus.GRCm39.${ENSEMBL_RELEASE}.gtf
OUTPUT=$(pwd)/rseqc_gene_models.bed

echo ensembl release: $ENSEMBL_RELEASE

#COMMAND(s) TO RUN
gawk '{if($0 ~ "transcript_id") print $0;\
    else print $0" transcript_id \"\";"}' ${GTFPATH}\
    | gtf2bed - > converted.bed

gawk -v OFS="\t" -F"\t| |;"\
     'BEGIN{first_tx=0}
      {gsub("; ",";")}\
      (NR == FNR && $8 != "exon")\
      	  {next}\
      (NR == FNR && $8 == "exon")\
          {
		tid=1
		eid=1
		while ($eid != "exon_id"){
		     eid++ 
		}
		while ($tid != "transcript_id"){
		     tid++
		}
		tid++
		eid++
		ex_start[$tid][$eid]=$2
		ex_end[$tid][$eid]=$3
		next
	  }\
      (NR != FNR && $8 == "transcript")\
	  {  	
		tid=1
		while ($tid != "transcript_id"){
		     tid++
		}
		tid++
		m=asort(ex_start[$tid],exs,"@val_num_asc")
		n=asort(ex_end[$tid],exe,"@val_num_asc")
		gsub("\042","",$tid)
		if(first_tx == 0){
	  	       printf($1"\t"$2"\t"$3"\t"$tid"\t""0""\t"$6"\t"$2"\t"$3"\t""0""\t"m"\t")
		       for(i=1; i <=m; i++){
		       	     printf((exe[i] - exs[i])",")
		       }
		       printf("\t")
		       for(i=1; i <=m; i++){
		       	     printf((exs[i] - $2)",")
		       }
		       first_tx=1
		}
		else{
	  	       printf("\n"$1"\t"$2"\t"$3"\t"$tid"\t""0""\t"$6"\t"$2"\t"$3"\t""0""\t"m"\t")
		       for(i=1; i <=m; i++){
		       	     printf((exe[i] - exs[i])",")
		       }
		       printf("\t")
		       for(i=1; i <=m; i++){
		       	     printf((exs[i] - $2)",")
		       }
		}
		$tid="\042" $tid "\042"
	  }' converted.bed converted.bed > $OUTPUT

rm converted.bed

#JOB LOG FOOTER
perl -E 'say"="x80'; echo "JOB COMPLETED: `date`"; perl -E 'say"="x80'
