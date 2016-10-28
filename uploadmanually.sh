#!/bin/bash
set -e
echo "load modules"


Rscript $UPLOADANNOT formattedoutput/${1}.hg19_multianno_clean.tsv ${dharma_id} DNAseq syn7450473
echo "first script worked"
Rscript $UPLOADANNOT QC/${1}.raw.snps.indels.vcf ${dharma_id} DNAseq syn7450473
