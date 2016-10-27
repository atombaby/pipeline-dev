#!/usr/bin/env Rscript
args=commandArgs(trailingOnly = TRUE)

#for testing
targetfilename <- '15JAA58PMN.tsv'
targetdharma_id <- 4
targetdata_type <- 'DNAseq'
pipelinefile<- 'syn7450473'

targetfilename  <- args[1] #path to target file you want to upload
targetdharma_id <- args[2] 
targetdata_type <- args[3] #string like "DNAseq" or "RNAseq"
pipelinefile <- args[4] #synID of pipeline file used

require(synapseClient)
require(REDCapR)

library(synapseClient)
synapseLogin('cocoauploader','rambleon!',rememberMe=F)

library(REDCapR)
results <- redcap_read(redcap_uri = 'https://cdsweb07.fhcrc.org/redcap/api/',
                       token = 'E34D9B9D1C7A2BD1962050BC30A13A9A',
                       records = targetdharma_id,
                       raw_or_label = "raw",
                       export_data_access_groups = TRUE)

toclean<-results$data
metadataALL <- toclean[-grep("_complete",colnames(toclean))]

rmeta <-redcap_metadata_read(redcap_uri = 'https://cdsweb07.fhcrc.org/redcap/api/',
                             token = 'E34D9B9D1C7A2BD1962050BC30A13A9A')
rmetaselect<-rmeta[[1]][,1:2]

#check the data access group and assign parent folder to the correct
#synID of the folders created for the data set ahead of time!!!  This allows
#us to require setting the permissions first.
if (metadata$redcap_data_access_group == 'paguirigan') {
    parentfolder='syn7354197'
    variselect<-rmetaselect[grep("min_|paguiriganclonality",rmetaselect$form_name),]
    metadata<- metadataALL[, colnames(metadataALL) %in% variselect$field_name]
} else if (metadata$redcap_data_access_group == 'radich') {
    parentfolder='syn7354198'
    variselect<-rmetaselect[grep("min_|radichcardinal",rmetaselect$form_name),]
    metadata<- metadataALL[, colnames(metadataALL) %in% variselect$field_name]
} else print('Data Access Group invalid')

#Figure out which subdir to save the data in based on what type of data the file is
query_results = synQuery('select name from folder where parentId==\"syn7354197\"')

if(targetdata_type=='RNAseq') {
    subdir=query_results[query_results$folder.name == 'RNAsequencing',]$folder.id
    annots<- metadata[-grep("dna_seq_|snp_array_|exp_array_|custom_omics",colnames(metadata))]
} else if(targetdata_type=='DNAseq') {
    subdir=query_results[query_results$folder.name == 'DNAsequencing',]$folder.id  
    annots<- metadata[-grep("rna_seq_|snp_array_|exp_array_|custom_omics",colnames(metadata))]
} else if(targetdata_type=='SNParray') {
    subdir=query_results[query_results$folder.name == 'SNParray',]$folder.id 
    annots<- cleaner[-grep("dna_seq_|rna_seq_|exp_array_|custom_omics",colnames(cleaner))]
} else if(targetdata_type=='EXParray') {
    subdir=query_results[query_results$folder.name == 'Expressionarray',]$folder.id 
    annots<- metadata[-grep("dna_seq_|snp_array_|rna_seq_|custom_omics",colnames(metadata))]
} else if(targetdata_type=='Custom') {
    subdir=query_results[query_results$folder.name == 'Custom',]$folder.id 
    annots<- metadata[-grep("dna_seq_|snp_array_|exp_array_|rna_seq_",colnames(metadata))]
} else print('Target Data Type invalid')

upfile <- File(targetfilename, parentId=subdir$properties$id)
synSetAnnotations(upfile)<-as.list(annots)
upfile <- synStore(upfile, executed=pipelinefile) # sends annotated file up