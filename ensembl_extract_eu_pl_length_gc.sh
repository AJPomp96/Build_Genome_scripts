#!/bin/bash
#SBATCH --output=./slurm-out/extract-%j.out
#SBATCH --job-name=ensemblExtract
#SBATCH --mem=32000
#SBATCH -c 1

#JOB LOG HEADER
perl -E 'say"="x80'; echo "JOB STARTED: `date`"; echo "NODE: `hostname`"; echo "SCRIPT ${0}:"; echo "JOB ID: ${SLURM_JOB_ID}"; cat $0; perl -E 'say"="x80'

#SOFTWARE REQUIREMENTS

#VARIABLES

export SPLITDIR="$(pwd)/Separate_Genes"
export igtf="Mus_musculus.GRCm39.${ENSEMBL_RELEASE}.gtf"
export fasta="Mus_musculus.GRCm39.dna.primary_assembly.fa"
export SPLITERR=${SPLITDIR}/bad_genes.txt
export RESFILE=EnsMm_grc39_${ENSEMBL_RELEASE}_Length_GC.tsv

echo igtf: ${igtf}
echo resfile: $RESFILE

#COMMAND(s) TO RUN

if [ ! -d ${SPLITDIR} ]
then
    echo $SPLITDIR
    mkdir $SPLITDIR
else
    echo $SPLITDIR
    rm -rf $SPLITDIR
    mkdir $SPLITDIR
fi

gawk -v SD=${SPLITDIR} \
     -v FS="\t| |;" \
'{
    gsub(/;\040+/,";");          # Convert "; " delimiters to ";"
    gsub(/\042/, "", $10);       # Strip " quotes from field 10
    arr[NR] = $10;               # Store Field 10 values in an array
}
# Write exons from input gtf file to separate gtf files named by gene ID
{
    $10 = "\042" $10 "\042";                                # Restore $10 quotes
    if($3 == "exon"){
        i=0
	printf $1"\t"$2"\t"$3"\t"$4"\t"$5\
	    "\t"$6"\t"$7"\t"$8"\t" >> SD"/"arr[NR]".gtf"
        for(i=9; i <=NF; i++){
            if(i % 2 == 1){
                printf $i" " >> SD"/"arr[NR]".gtf"
            }
            else{
                printf $i"; " >> SD"/"arr[NR]".gtf"
            }
        }
        print "" >> SD"/"arr[NR]".gtf"
    }
}
{
    gsub(";","; ")
}' $igtf

for f in $(ls ${SPLITDIR}); do
    
    g=$(echo $f | sed 's/\.gtf//')        # Store the Gene ID in a variable

    # Check the number of chromsomes (should only be one)
    nc=$(
	cat ${SPLITDIR}/$f\
	    | cut -f1 | sort | uniq\
	    | wc -l| sed 's/[[:space:]]//g'
      )

    # Check the number of strand orientations (should only be one)
    ns=$(
	cat ${SPLITDIR}/$f\
	    | cut -f6 | sort | uniq\
	    | wc -l| sed 's/[[:space:]]//g'
      )

    # Stop processing this gene on chromsome error
    if [ $nc -gt 1 ]; then
	echo $g has features on multiple chromosomes >> ${SPLITERR}
	cat ${SPLITDIR}/$f >> ${SPLITERR}
	continue
    fi

    # Stop processign this gene on strand error, otherwise process
    if [ $ns -gt 1 ]; then
	echo $g has features on multiple strands >> ${SPLITERR}
	cat ${SPLITDIR}/$f >> ${SPLITERR}
	continue

    else
	# read set of exons, sort by start position, calculate exon lengths
	# and nucleotide content -- passed to gawk for processing
	cat ${SPLITDIR}/$f \
            | sort -k4,4n\
	    | bedtools nuc -s -fi ${fasta} -bed stdin\
	    | gawk \
	    '(NR > 1 && NR == FNR)\
             {
                 FS="\t"                                 # split on tab
                 gsub(/;\040+/,";")                      # "; " becomes ";"
                 gsub(/\042/,"")                         # drop quotes
                 split($9,atr,";| ")               # Store field 9 in array atr      
                 gid[atr[2]]                       # Store gene id as array key
                 tlen[atr[6]]=tlen[atr[6]] + $18   # sum exon lengths by txid
                 if($0 ~ /appris_principal/){    # Flag "P" if principal
                    tprn[atr[6]]="P"                 
                 }
                 else{
                     tprn[atr[6]]="N"              # Flag "N" if not principal
                 }
                 txgc[atr[6]]=txgc[atr[6]] + $13 + $14
             }
             # After loading 
             (FNR != NR && $1 in gid){
                    FS="\t"                        
                    for(g in gid){
                        l = 0                      # max non-principal tx len
                        m = 0                      # max principal tx len 
                        longest = ""               # id of longest "N" tx  
                        principal =""              # id of longest "P" tx
                        
                        # Iterate over transcripts and identify longest
                        # principal and non-principal
                        for(t in tlen){
                            if(tprn[t] == "P" && tlen[t] > m){  
                                principal=t
                                m=tlen[t]
                            }
                            else if(tlen[t]>l && m == 0){
                                longest=t
                                l=tlen[t]
                            }
                            
                        }
                        # Return either the longest principal transcript
                        if(m > 0)
                            print $1"\t" principal "\t" $2 "\t" $3 "\t"\
                                  tlen[principal]"\t"\
                                  txgc[principal] / tlen[principal]"\t"\
                                  tprn[principal]
                        
                        # Or if none exists, the longest transcript 
                        else
                            print $1"\t" longest "\t" $2 "\t" $3 "\t"\
                                  tlen[longest]"\t"\
                                  txgc[longest] / tlen[longest] "\t"\
                                  tprn[longest]
                    }
                }' /dev/stdin\
		    <(
		# Calculate Exon-Union Length & GC content using
		# bedtools merge to flatten overlapping exons
		       cat ${SPLITDIR}/$f\
			   | sort -k4,4n\
			   | gawk -v FS="\t| |;"\
           	           '\
                           {
                               gsub(/;\040+/,";")
                               gsub(/\042/,"")
                               for(i=1; i<9;i++){printf($i"\t")}
                               print($10)
                           }'\
			   | bedtools merge -s -i stdin -c 7,9 -o distinct\
			   | gawk -v OFS="\t"\
				  '{print $1, $2, $3, $5, ".", $4, $3 - $2}'\
			   | bedtools nuc -s -fi ${fasta} -bed stdin\
			   | gawk '(NR > 1)'\
		       	   | bedtools groupby -g 4\
				      -c 10,11,12,13,14,15,16 -o sum\
			   | gawk -v OFS="\t" '{print $1, $8, ($3 + $4) / $8}'
	            ) >> ${RESFILE}
    fi
done

rm -rf ${SPLITDIR}

#JOB LOG FOOTER
perl -E 'say"="x80'; echo "JOB COMPLETED: `date`"; perl -E 'say"="x80'
