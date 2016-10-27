Upstream:  Manual ingest would be to input for dharma_id's in redcap, the relevant data all the way to the location of the raw data you want to process/ingest, as well as the file stems for those files that match with the dharma ids/directories.  

Then download a csv containing those three columns (sample name, dharma_id and directory), and start an array job with those?  

Below would be the bash script running the processing assuming there are three inputs for each job in the array.  
---------------------------------------------------------------------------------------------

#!/bin/bash
set -e

filestem=$1
dharma_id=$2
rawdata_loc=$3

echo $@
datatype="DNASeq" #this is specific to the pipeline itself, so it's known. 

---------------------------------------------------------------------------------------------
#pull annotations from REDcap and store, retrieve relevant raw data location and assign
#we are pulling the record(s) associated with the dharma_id value only, and need to pull 
#down all non-PHI fields, which if we give the synapseconnection user only non-PHI access, 
#then we just pull down the default (all fields)
#exportDataAccessGroups=true
#Have made all the rawOrLabel fields appropriate, so that the default (raw) can be taken

---------------------------------------------------------------------------------------------
#Do some sort of minimal annotation check to make sure all relevant data exist for this 
#sample prior to analyzing it.  

---------------------------------------------------------------------------------------------
#Call Pipeline Script

---------------------------------------------------------------------------------------------
#Upload output file to synapse from Tom, already in github

upload.py 

---------------------------------------------------------------------------------------------
#Annotate Synapse file with remaining and newly defined annotations from pipeline
pipeline=ScriptID
pipelineAuthor=Paguirigan
pipelineGithub=XXXX #or synID of each github entity we want to use as data provenance?

---------------------------------------------------------------------------------------------
echo "You're done. Consider returning the synId of the entity created as a QC check."








