#!/usr/bin/env Rscript
args=commandArgs(trailingOnly = TRUE)

#suppressPackageStartupMessages({library(plyr); library(dplyr)})

#For testing
#args <- array(1:2)
#args[1]<- "./annovar/AML438.hg19_multianno.txt"

inputfilename  <- args[1]

outputfilename <- gsub(".txt", "", gsub("annovar/", "", args[1]))

data<- read.delim(inputfilename, skip=1, header=F)

#colsNamed<- read.delim("AML438.hg19_multianno.txt", skip=0, header=F, nrows=1, 
#                       stringsAsFactors = F)
#cat(paste(shQuote(colsNamed,type="cmd"), collapse = ", ")) 
# to generate and print the names in colsNamed
    
    
colsNamed <- c("Chr", "Start", "End", "Ref", "Alt", "Func.refGene", "Gene", 
               "GeneDetail.refGene", "ExonicFunc.refGene", "AAChange.refGene", 
               "esp6500siv2_all", "ExAC_ALL", "ExAC_AFR", "ExAC_AMR", "ExAC_EAS", 
               "ExAC_FIN", "ExAC_NFE", "ExAC_OTH", "ExAC_SAS", "ExAC_nontcga_ALL", 
               "ExAC_nontcga_AFR", "ExAC_nontcga_AMR", "ExAC_nontcga_EAS", 
               "ExAC_nontcga_FIN", "ExAC_nontcga_NFE", "ExAC_nontcga_OTH", 
               "ExAC_nontcga_SAS", "cosmic70", "1000g2015aug_all", 
               "1000g2015aug_afr", "1000g2015aug_eas", "1000g2015aug_eur", 
               "snp138", "SIFT_score", "SIFT_pred", "Polyphen2_HDIV_score", 
               "Polyphen2_HDIV_pred", "Polyphen2_HVAR_score", "Polyphen2_HVAR_pred", 
               "LRT_score", "LRT_pred", "MutationTaster_score", "MutationTaster_pred", 
               "MutationAssessor_score", "MutationAssessor_pred", "FATHMM_score", 
               "FATHMM_pred", "PROVEAN_score", "PROVEAN_pred", "VEST3_score", 
               "CADD_raw", "CADD_phred", "DANN_score", "fathmm-MKL_coding_score", 
               "fathmm-MKL_coding_pred", "MetaSVM_score", "MetaSVM_pred", 
               "MetaLR_score", "MetaLR_pred", "integrated_fitCons_score", 
               "integrated_confidence_value", "GERP++_RS", "phyloP7way_vertebrate", 
               "phyloP20way_mammalian", "phastCons7way_vertebrate", 
               "phastCons20way_mammalian", "SiPhy_29way_logOdds", "Otherinfo", 
               "QUAL","DP", "CHROM", "POS", "ID", "REF.full", "ALT.full", "QUAL2", 
               "FILTER", "INFO", "FORMAT", "VARDATA")
colnames(data)<- colsNamed
clean <- subset(data, select=-c(CHROM, POS, ID, QUAL2, Otherinfo, FORMAT, INFO))
clean$VariantID <- paste(clean$Chr,clean$Gene, clean$Start, 
                                      clean$Ref, clean$Alt, sep=";")

#doublevar <- clean[grep(",",clean$ALT),]
#This doesn't currently address the occasional double variant on the same line
#in annovar.  Currently just leaves it as is and deals with it at the VAF calc.
cleaner <- clean
cleaner$AD <- as.numeric(gsub(":.*","", sub("./.:[0-9]*,","", clean$VARDATA)))

cleaner$VAF <- 100*cleaner$AD/cleaner$DP

neworder <- c("Chr", "Start", "End", "Ref", "Alt", "AD", "DP", "VAF", "Gene", 
              "VariantID", "QUAL", "Func.refGene",
              "GeneDetail.refGene", "ExonicFunc.refGene", "AAChange.refGene", 
              "esp6500siv2_all", "ExAC_ALL", "ExAC_AFR", "ExAC_AMR", "ExAC_EAS", 
              "ExAC_FIN", "ExAC_NFE", "ExAC_OTH", "ExAC_SAS", "ExAC_nontcga_ALL", 
              "ExAC_nontcga_AFR", "ExAC_nontcga_AMR", "ExAC_nontcga_EAS", 
              "ExAC_nontcga_FIN", "ExAC_nontcga_NFE", "ExAC_nontcga_OTH", 
              "ExAC_nontcga_SAS", "cosmic70", "1000g2015aug_all", 
              "1000g2015aug_afr", "1000g2015aug_eas", "1000g2015aug_eur", 
              "snp138", "SIFT_score", "SIFT_pred", "Polyphen2_HDIV_score", 
              "Polyphen2_HDIV_pred", "Polyphen2_HVAR_score", "Polyphen2_HVAR_pred", 
              "LRT_score", "LRT_pred", "MutationTaster_score", "MutationTaster_pred", 
              "MutationAssessor_score", "MutationAssessor_pred", "FATHMM_score", 
              "FATHMM_pred", "PROVEAN_score", "PROVEAN_pred", "VEST3_score", 
              "CADD_raw", "CADD_phred", "DANN_score", "fathmm-MKL_coding_score", 
              "fathmm-MKL_coding_pred", "MetaSVM_score", "MetaSVM_pred", 
              "MetaLR_score", "MetaLR_pred", "integrated_fitCons_score", 
              "integrated_confidence_value", "GERP++_RS", "phyloP7way_vertebrate", 
              "phyloP20way_mammalian", "phastCons7way_vertebrate", 
              "phastCons20way_mammalian", "SiPhy_29way_logOdds", 
              "REF.full", "ALT.full",  "VARDATA")  

cleanest <- cleaner[,neworder]
dir.create("./formattedoutput", showWarnings=FALSE)
write.table(cleanest, file = paste("./formattedoutput/",outputfilename,"_clean.tsv", sep=""), sep = "\t", row.names = FALSE) 
