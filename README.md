#How we've cobbled this together so far

#Current approach:

##List of file stems (old skool version that works)
I save the column of the above csv containing the sample names (file stems) as 
text file in the directory containing the fastq's (the project folder).  This
means I can only process the files in that directory as a group!!  

##Generate individual batch scripts
C/P in the sample names (file stems) from above into the text of the
batchScriptMaker-TargDNASeq.sh.  It makes one script per sample that looks like
t1.sbatch.  It refers to database references in various lcoations both private 
to me and shared to all, which means only my user can submit these jobs now.  :(
The script it calls is: pipe-XXX-TargDNA-Unpaired-Rclean.sh, and a formatting
script I wrote in R b/c I could (but is not rocket science) called
TruSight-Reformat.R. 

##Run all scripts
Just do:
for file in t*batch; do sbatch $file; done

To get all the scripts to run independently and then you have to track every 
job separately even though likely if one fails, the others will too.  

##Results
This runs a bunch of stems/scripts in a project directory in which there is a subdir
called 'fastq' that contains fastq's with the filestem as sample_name.  It will 
load modules, run all the steps using BWA-MEM, picard, GATK, annovar and a
reformatting R script I wrote.  Then it will create directories in that project 
folder for all of the different files generated, but does not share the data to
synapse or pull annotations from REDcap.  That aspect has to be done manually 
and it's a total slog that I have not had the time to invest in doing yet.  It'd
have to be done directory by directory, and data type by data type, etc.  

#More Ideal Approach:

##Export sample metadata from REDcap
I have some saved reports in my REDcap project that I can filter and select only 
the samples I want to process and put in synapse.  An example of this file is
exampleDatatorun.csv. This makes it easier to do a batch at a time.  For new 
data generated from Hutchbase, this wouldn't be required. For all old data, we'd
have to semi-manually curate the REDcap info so we can tell it where the data
are.  This is likely going to always need some level of human involvement to make
sure it's done right, b/c the input data is always going to be messy (otherwise 
why would you be doing this?).

##Array job (new skool version that doesn't work yet)
For each line in the csv made above, I'd like to get an array job which would
pass each individual job the parameters it needs on each individual line of the csv.

So this would replace the batchscriptmaker and the sbatch t*batch step.

Ideally it would be run somewhere central, but 
would look for the various data files in the directories specified, assuming it 
had the permissions for them.  That way you could run the same analysis on files 
in aritrary directories assuming the user who ran the script had permissions for
all of them. When things were made via Hutchbase, this is less of an issue, but
all incoming data from elsewhere or any older data set would need to be run 
through a pipeline such as this.  ALSO, if we ever wanted to keep using legacy 
data but say re-map it to some future genome version or go back and use a 
different variant caller, we'd have to do this all again anyway. So this would 
be used every time we wanted to share data made previous to Hutchbase doing this
(which it is not yet), people wanted to share data made by other institutions,
or anytime we generate a new pipeline through which we want to put a set of old 
data through.

##Process that data, share to synapse with annotations from REDcap
The array job would call the pipeline script for targ seq, variant calling like
this:

/somewhere/in/the/filesystem/Haplotype-TruSightMyeloid-Pipeline.sh filestem 
/fh/fast/radich_j/SR/ngs/illumina/160830_Somedata 250

(which is: script.sh {filestem} {directory} {dharma_id})

This script should then do all of the processing steps, PLUS call this script:
Haplotype-TruSightMyeloid-Pipelineuploadannotate.R, that hasn't been tested on 
the cluster, but works on my machine, which is why I had the module loading 
issue b/c I needed the R packages REDCapR and synapseClient.  Neither of these 
need to be written in R (synapse python client is apparently WAY better), I just
decided to DIY it with my duct tape and get 'er done so I could at least more
accurately explain what needs to happen.  If I did it in R I could get it to work
in an hour.  

##Results
In this scenario, it seems that the script would run somewhere where it is ok 
that the intermediate files would live (that the researcher wouldn't want?).  
It would go hunt down data in arbitrary places, with names and dharma id's that
we provide it via the csv, (or even better directly from the report from REDcap!!).
Then process the data, make and save the intermediate files in pwd, then when 
it's done, will get file annotations and location instructions from REDcap 
(such as what Data Access Group the entry is in, and thus which location in 
Synapse it needs to save the files so that the right people have access to the
processed files).  Then it will upload the file to the correct location in synapse,
annotate them, and provde data provenance (the pipeline it was run through which
needs to be in synapse first).  

Then the processed files live in the filesystem and also in synapse with full
annotations there.  


