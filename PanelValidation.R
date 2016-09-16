#!/usr/bin/env Rscript
#Go to main directory for the data set of interest first.
#setwd("/Volumes/fh-3/fast/radich_j/SR/ngs/illumina/apaguiri/160830_ADWAR")

#Read in all the data files for each sample processed that are in the QC dir
filenames <- list.files(path = "./QC", pattern = "*..depth.sample_interval_summary",
                        full.names = TRUE)
intsum <- lapply(filenames, read.delim, stringsAsFactors = FALSE) 

#Select out the target and mean coverage per base in the interval for each sample
dataout<- lapply(intsum, '[', ,c(1,5))
datamerge <- Reduce(function(x,y) merge(x,y, all=TRUE, suffuxies=c("","")), dataout)
rownames(datamerge)<-datamerge[,1]
datamerge[,1]<-NULL

write.table(datamerge, file="PanelQCsummaryforRun.tsv", quote=FALSE, 
            row.names = TRUE, col.names = NA, sep = "\t")
