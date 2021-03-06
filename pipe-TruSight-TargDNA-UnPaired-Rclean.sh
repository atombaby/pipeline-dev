#!/bin/bash

# pipe-TruSight-TargDNA-UnPaired-Rclean.sh <path to report>

set -e

# Check for slurm array job

if [ -z ${SLURM_ARRAY_TASK_ID+x} ]
then
        echo "SLURM_ARRAY_TASK_ID is unset- are we in a job?" >&2
        exit 1
fi

# Check for existence of the RedCap report with dharma id's for samples

if [ -r ${1} ]
then
        AWKSTRING="\$3 == \"$SLURM_ARRAY_TASK_ID\" {print \$1,\$2}"
        TGT=($(awk -F',' "$AWKSTRING" ${1}))
        root=${TGT[0]}
        parent=$(dirname ${TGT[1]})
        echo "Working on source files $root in $parent"
else
        echo "Sample database (${1}) does not exist or is unreadable" >&2
        exit 1
fi

##updated packages on 8/30/2016##
module load \
    BWA/0.7.12-foss-2015b \
    SAMtools/1.3.1-foss-2016a \
    BEDTools/2.23.0-foss-2015b \
    GATK/3.5-Java-1.8.0_66 \
    picard/2.0.1-Java-1.8.0_66 \
    annovar/2016Feb01

echo "Set Directory containing fastq's"
dataDir=fastq
 
##Declare Common Paths##
REFDATA=/fh/fast/paguirigan_a/GenomicsArchive
HG19FA=${REFDATA}/GATKBundle/160830/ucsc.hg19.fasta
BWAHG19=${REFDATA}/GATKBundle/160830/ucsc.hg19.fasta
ANNOVARDB=/shared/biodata/humandb

# Command Aliases
JAVAOPTS='-Xmx4G'
GATK="java $JAVAOPTS -jar $EBROOTGATK/GenomeAnalysisTK.jar"
PICARD="java $JAVAOPTS -jar $EBROOTPICARD/picard.jar SortSam"
ANNOVAR=$EBROOTANNOVAR

# GATK bundle data v2.8 available from 
# ftp://ftp.broadinstitute.org/bundle/2.8/
BUNDLE=${REFDATA}/GATKBundle/160830
SNP138=$BUNDLE/dbsnp_138.hg19.vcf
INDEL1000G=$BUNDLE/1000G_phase1.indels.hg19.sites.vcf
INDEL1000GnMill=$BUNDLE/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf

REFORMAT=${REFDATA}/TruSightMyeloid/TruSight-Reformat.R


##Bed files##
TARGET=${REFDATA}/TruSightMyeloid/trusight-myeloid-amplicon-track.bed
INTERVAL=${REFDATA}/TruSightMyeloid/trusight-myeloid-amplicon-track_interval.bed

cd $parent
mkdir -p bwa
echo "Using BWA MEM to map paired-reads to ref genome hg19"
bwa mem \
    -t 8 -M \
    -R "@RG\tID:${TGT}\tLB:${TGT}\tSM:${TGT}\tPL:ILLUMINA" $BWAHG19 \
    ${dataDir}/${TGT}.R1.fastq.gz \
    ${dataDir}/${TGT}.R2.fastq.gz > bwa/${TGT}.sam 2> bwa/${TGT}_aln.err

echo "BWA-MEM complete"

mkdir -p picard
echo "clean and sort sam/bam, mark duplicate reads, and index"
${PICARD} \
	I=bwa/${TGT}.sam \
	O=picard/${TGT}.bam \
	VALIDATION_STRINGENCY=LENIENT \
	TMP_DIR=$PWD/tmp \
	SO=coordinate

samtools index picard/${TGT}.bam

echo "Picard and samtools indexing complete"

mkdir -p GATK
echo "Realign, then index"
${GATK} -T RealignerTargetCreator \
	-R $HG19FA \
	-I picard/${TGT}.bam \
	-o GATK/${TGT}.realigner.intervals \
	-L $TARGET \
	-ip 100 \
	-known $INDEL1000G \
	-known $INDEL1000GnMill

${GATK} -T IndelRealigner \
	-R $HG19FA \
	-I picard/${TGT}.bam \
	-o GATK/${TGT}.realigned.bam \
	-targetIntervals GATK/${TGT}.realigner.intervals \
	-known $INDEL1000G \
	-known $INDEL1000GnMill


echo "Base recalibration"
${GATK} -T BaseRecalibrator \
	-R $HG19FA \
	-I GATK/${TGT}.realigned.bam \
	-L $TARGET \
	-ip 100 \
	-knownSites $INDEL1000G \
	-knownSites $INDEL1000GnMill \
	-knownSites $SNP138 \
	-o GATK/${TGT}_recal.grp

${GATK} -T PrintReads \
	-R $HG19FA \
	-I GATK/${TGT}.realigned.bam \
	-L $TARGET \
	-ip 100 \
	-BQSR GATK/${TGT}_recal.grp \
	-o GATK/${TGT}.realigned.recal.bam

echo "GATK realignment, recalibration complete"

mkdir -p QC
echo "Diagnostics and Quality Control"
echo "Generate overview"
samtools flagstat picard/${TGT}.bam > picard/${TGT}.flagstat.out

echo "Compute Number Of Reads  Bed File, Default minimum overlap is 1 bp"
intersectBed -v -wa -abam picard/${TGT}.bam -b $TARGET -bed | wc -l > QC/${TGT}.intersectBed.out

echo "Compute Read Depths"
${GATK} -T DepthOfCoverage \
	-R $HG19FA \
	-I GATK/${TGT}.realigned.recal.bam \
	-L $TARGET \
	-omitBaseOutput \
	-omitLocusTable \
	-S SILENT \
	-ct 10 -ct 15 -ct 20 \
	-o QC/${TGT}.depth

echo "Variant calling using HaplotypeCaller"
${GATK} -T HaplotypeCaller \
	-R $HG19FA \
	-I GATK/${TGT}.realigned.recal.bam \
	-L $TARGET \
	--dbsnp $SNP138 \
	-stand_call_conf 30 \
	-stand_emit_conf 10 \
	-o QC/${TGT}.raw.snps.indels.vcf

echo "QC, Depth of coverage and variant calling complete"

echo "Clean up files"
if [ -f $PWD/${TGT}.depth.sample_summary ]; then 
    rm bwa/${TGT}.sam
fi


echo "Annotate VCF files then reformat it to extract the required info"

ANOVAR_PROTOCOLS="refGene,esp6500siv2_all,exac03,exac03nontcga,cosmic70,1000g2015aug_all"
ANOVAR_PROTOCOLS="${ANOVAR_PROTOCOLS},1000g2015aug_afr,1000g2015aug_eas,1000g2015aug_eur,snp138,dbnsfp30a"

mkdir -p annovar

perl $ANNOVAR/table_annovar.pl QC/${TGT}.raw.snps.indels.vcf $ANNOVARDB \
    -buildver hg19 \
    -out annovar/${TGT} \
    -remove \
    -protocol ${ANOVAR_PROTOCOLS} \
    -operation g,f,f,f,f,f,f,f,f,f,f \
    -nastring . -vcfinput

echo "Clean up format of output files in R"
Rscript $REFORMAT annovar/${TGT}.hg19_multianno.txt

echo "Keeping it 100."  


