#!/bin/bash
#SBATCH --output=./slurm-out/buildindx-%j.out
#SBATCH --job-name=buildMmIndex
#SBATCH --mem=256000
#SBATCH --ntasks=8

#JOB LOG HEADER
perl -E 'say"="x80'; echo "JOB STARTED: `date`"; echo "NODE: `hostname`"; echo "SCRIPT ${0}:"; echo "JOB ID: ${SLURM_JOB_ID}"; cat $0; perl -E 'say"="x80'

#SOFTWARE REQUIREMENTS

#VARIABLES

ENSEMBL_GRCm39_BASE=ftp://ftp.ensembl.org/pub/release-${ENSEMBL_RELEASE}/fasta/mus_musculus/dna
ENSEMBL_GRCm39_GTF_BASE=ftp://ftp.ensembl.org/pub/release-${ENSEMBL_RELEASE}/gtf/mus_musculus
GTF_FILE=Mus_musculus.GRCm39.${ENSEMBL_RELEASE}.gtf

HISAT2_BUILD_EXE=./hisat2-build
HISAT2_SS_SCRIPT=./hisat2_extract_splice_sites.py
HISAT2_EXON_SCRIPT=./hisat2_extract_exons.py

F="Mus_musculus.GRCm39.dna.primary_assembly.fa.gz"
GENOME=$(echo $F | sed 's/\.gz//')

echo $ENSEMBL_RELEASE

#COMMAND(s) TO RUN
get() {
        file=$1
	if ! wget --version >/dev/null 2>/dev/null ; then
                if ! curl --version >/dev/null 2>/dev/null ; then
                        echo "Please install wget or curl somewhere in your PATH"
                        exit 1
                fi
                curl -o `basename $1` $1
                return $?
        else
                wget -nv $1
                return $?
	fi
}


if [ ! -x "$HISAT2_BUILD_EXE" ] ; then
        if ! which hisat2-build ; then
                echo "Could not find hisat2-build in current directory or in PATH"
                exit 1
        else
                HISAT2_BUILD_EXE=`which hisat2-build`
	fi
fi

if [ ! -x "$HISAT2_SS_SCRIPT" ] ; then
        if ! which hisat2_extract_splice_sites.py ; then
                echo "Could not find hisat2_extract_splice_sites.py in current directory or in PATH"
                exit 1
        else
                HISAT2_SS_SCRIPT=`which hisat2_extract_splice_sites.py`
        fi
fi

if [ ! -x "$HISAT2_EXON_SCRIPT" ] ; then
        if ! which hisat2_extract_exons.py ; then
                echo "Could not find hisat2_extract_exons.py in current directory or in PATH"
		exit 1
        else
                HISAT2_EXON_SCRIPT=`which hisat2_extract_exons.py`
        fi
fi

if [ ! -f $GTF_FILE ] ; then
       get ${ENSEMBL_GRCm39_GTF_BASE}/${GTF_FILE}.gz || (echo "Error getting ${GTF_FILE}" && exit 1)
       gunzip ${GTF_FILE}.gz || (echo "Error unzipping ${GTF_FILE}" && exit 1)
fi

#fix Lim2/Gm52993 error
#Lim2 is obscured by a nonsense mediated decay transcript
#prune Gm52993 from gtf file
tmpfile=$(mktemp)
INTERFERING_ID=ENSMUSG00000093639

wc -l $GTF_FILE

cat $GTF_FILE\
    | grep -v $INTERFERING_ID > ${tmpfile}

cat ${tmpfile} > $GTF_FILE

rm -f ${tmpfile}

wc -l $GTF_FILE

if [ ! -f genome.ss ] ; then
       ${HISAT2_SS_SCRIPT} ${GTF_FILE} > genome.ss
       ${HISAT2_EXON_SCRIPT} ${GTF_FILE} > genome.exon
fi

if [ ! -f $GENOME ] ; then
    get ${ENSEMBL_GRCm39_BASE}/${F} || (echo "Error Fetching $F" && exit 1)
    gunzip $F
fi

echo hisat2-build -f -p 8 --ss genome.ss --exon genome.exon $GENOME EnsMm_grc39_${ENSEMBL_RELEASE}
hisat2-build -f -p 8 --ss genome.ss --exon genome.exon $GENOME EnsMm_grc39_${ENSEMBL_RELEASE}

#JOB LOG FOOTER
perl -E 'say"="x80'; echo "JOB COMPLETED: `date`"; perl -E 'say"="x80'
