#!/bin/bash
#SBATCH -N1 -n4 -t 1-12 -p campus --mail-type=END --mail-user=EMAIL MOABACCOUNT

echo "Initialize vars from arguments"
filestem=${1}
dataDir=${2}
dharma_id=${3}



## example params passed by the Plugin
##paired=false
##runFolder=110927_HWI-EAS88_0099
##transferRoot=/shared/ngs/
##platform=illumina
##flowCell=sadfdasdaa
##runDirectory=/shared/ngs_spool/illumina/110927_HWI-EAS88_0099
##transferDirectory=/shared/ngs/illumina/lmaves/110927_HWI-EAS88_0099
##user=lmaves
##emailList=dwaring@fhcrc.org
##barcodeSequence=ACAGTG
##runFastQC=true
##genomeBuild=/shared/solexa/solexa/Genomes/ELAND/danioRerio/zv9.63/bowtie/Zv9.63
##gtfFile=/shared/solexa/solexa/Genomes/ELAND/danioRerio/zv9.63/gtf/Danio_rerio.Zv9.63.gtf
##sampleName=LM5-zfwta
##filter=false
##lane=4

#umask 0002

export PATH=/usr/kerberos/bin:/usr/local/bin:/bin:/usr/bin:/usr/X11R6/bin:/opt/moab/bin:$bowtieVersion:$tophatVersion:/home/solexa/apps/samtools/samtools-0.1.19:/home/solexa/apps/FastQC
#remove /app/bin from the PATH, as it will default to running bowtie 0.12.8
export PATH=${PATH/\/app\/bin:}
sampleDir=$transferDirectory/Unaligned/Project_$user/Sample_$sampleName/


cd $sampleDir

## fastqc
if [ $runFastQC = "true" ]; then
	fastqFiles1=`ls -m *_R1_0*.fastq.gz | sed -e 's/,/ /g' | tr -d '\n'`
	fastqFiles2=`ls -m *_R2_0*.fastq.gz | sed -e 's/,/ /g' | tr -d '\n'`
	fastqcOutDir=$transferDirectory/fastqc
	mkdir -p $fastqcOutDir
	fastqc -t 4 $fastqFiles1 -o $fastqcOutDir --casava
	if [ $paired = "true" ]; then
		fastqc -t 4 $fastqFiles2 -o $fastqcOutDir --casava
	fi
fi

## filter
if [ $filter = "true" ]; then
	filteredDirectory=$transferDirectory/filtered/$sampleName
	mkdir -p $filteredDirectory
	for i in *fastq.gz 
	do 
		i2=${i//.gz/} 
		zgrep -A 3 '^@.*[^:]*:N:[^:]*:' $i | zgrep -v '^\-\-$' > $filteredDirectory/$i2 
	done 
	gzip -r $filteredDirectory
	cd $filteredDirectory
fi

## run tophat
tophatOutDir=$transferDirectory/tophat/$sampleName
mkdir -p $tophatOutDir

if [ $paired = "true" ]; then
	fastqFilesR1=`ls -m *_R1_0*.fastq.gz | sed -e 's/, /,/g' | tr -d '\n'`
	fastqFilesR2=`ls -m *_R2_0*.fastq.gz | sed -e 's/, /,/g' | tr -d '\n'`
	tophat --mate-inner-dist $innerDist --num-threads 4 -G $gtfFile --library-type $libraryType -I $maxIntronLength --segment-length $segmentLength -o $tophatOutDir $genomeBuild $fastqFilesR1 $fastqFilesR2
else
	fastqFiles=`ls -m *.fastq.gz | sed -e 's/, /,/g' | tr -d '\n'`
	tophat --num-threads 4 -G $gtfFile --library-type $libraryType -I $maxIntronLength --segment-length $segmentLength -o $tophatOutDir $genomeBuild $fastqFiles
fi

#move bam files
bamDir=$transferDirectory/tophat/bam
mkdir -p $bamDir
mv $tophatOutDir/accepted_hits.bam $bamDir/$sampleName.bam

## process bam
cd $bamDir
#sort
samtools sort -@ 4 $sampleName.bam $sampleName.sorted
#mark duplicate reads
java -jar /home/solexa/apps/picard/picard-tools-1.114/MarkDuplicates.jar I=$sampleName.sorted.bam O=$sampleName.bam M=$sampleName.duplicateMetrics
rm $sampleName.sorted.bam
#add read group information: platform and sample
java -jar /home/solexa/apps/picard/picard-tools-1.114/AddOrReplaceReadGroups.jar I=$sampleName.bam O=$sampleName.info.bam LB=$sampleName PL=Illumina PU=$flowCell SM=$sampleName
rm $sampleName.bam
#reorder bam
tmpDir=`pwd`/$sampleName.tmp
java -jar /home/solexa/apps/picard/picard-tools-1.114/ReorderSam.jar I=$sampleName.info.bam O=$sampleName.bam R=$fasta TMP_DIR=$tmpDir
rm -rf $sampleName.tmp
rm $sampleName.info.bam
#index bam
samtools index $sampleName.bam


## RNA-SeQC
if [ $runRNASeqQC = "true" ]; then
#if ensembl gtf then -ttype2 or else point to ribosomal intervals file
#check to see how $singleEnd is represented in HutchBASE
	RNASeQCdir=$transferDirectory/RNA-SeQC/$sampleName
	mkdir -p $RNASeQCdir
	sampleInfo="$sampleName|$sampleName.bam|$sampleName"
	if [ $ribosomalIntervals = "" ]; then
		java -jar /home/solexa/apps/RNA-SeQC/RNA-SeQC_v1.1.7.jar -n 1000 -s $sampleInfo $singleEnd -t $gtfFile -r $fasta -o $RNASeQCdir -ttype 2
	else
		java -jar /home/solexa/apps/RNA-SeQC/RNA-SeQC_v1.1.7.jar -n 1000 -s $sampleInfo $singleEnd -t $gtfFile -r $fasta -o $RNASeQCdir -rRNA $ribosomalIntervals
	fi
fi


#HTSeq-count
if [ $libraryType="fr-unstranded" ]; then
	stranded=no
else
	stranded=yes
fi


if [ $runHTSeqCount = "true" ]; then
	htsOutDir=$transferDirectory/hts
	mkdir -p $htsOutDir
	if [ "$libraryType" = "fr-unstranded" ]; then
		stranded=no
	else
		stranded=reverse
	fi
	if [ "$libraryType" = "fr-secondstrand" ]; then
		stranded=yes
	fi
	echo $stranded
	if [ $paired = "true" ]; then
		samtools sort -@ 4 -n $bamDir/$sampleName.bam $htsOutDir/$sampleName
		if [ $outputSAM = "true" ]; then
			samOutDir=$htsOutDir/$sam
			mkdir -p $samOutDir
			python -m HTSeq.scripts.count -f bam -r name -m $overlapMode $htsOutDir/$sampleName.bam $gtfFile -s $stranded -o $samOutDir/$sampleName.sam > $htsOutDir/$sampleName.hts
		else
		python -m HTSeq.scripts.count -f bam -r name -m $overlapMode $htsOutDir/$sampleName.bam $gtfFile -s $stranded > $htsOutDir/$sampleName.hts
		fi
		rm $htsOutDir/$sampleName.bam
	else
		if [ $outputSAM = "true" ]; then
			samOutDir=$htsOutDir/$sam
			mkdir -p $samOutDir
			python -m HTSeq.scripts.count -f bam -r pos -m $overlapMode $bamDir/$sampleName.bam $gtfFile -s $stranded -o $samOutDir/$sampleName.sam > $htsOutDir/$sampleName.hts
		else
			python -m HTSeq.scripts.count -f bam -r pos -m $overlapMode $bamDir/$sampleName.bam $gtfFile -s $stranded > $htsOutDir/$sampleName.hts
		fi
	fi
fi


#delete filtered fastq files
if [ $deleteFilteredFiles = "true" ]; then
	rm -rf $transferDirectory/filtered/$sampleName
fi

#write job complete file
jobStatusDir=$transferDirectory/jobStatus
mkdir -p $jobStatusDir
touch $jobStatusDir/$sampleName.rnaSeqExpression_DONE.txt
exit 0


##this needs to be updated to reflect this pipeline specific info
Rscript $UPLOADANNOT ${1}.hts ${dharma_id} RNAseq syn7450473 {RNASeQC file path}


echo "Go look in synapse my friends. Consider returning the synId of the entity(s) created as a QC check."


