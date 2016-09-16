#How we've cobbled this together so far
##List of file stems
I generate and save a list of the file stems of every file in the /fastq/ directory
in a project folder.  

##Generate individual batch scripts
C/P in the sample names (file stems) from above into the text of the
batchScriptMaker-TargDNASeq.sh.  It makes one script per sample that looks like
t1.sbatch.

##Run all scripts
Just do:
for file in t*batch; do sbatch $file; done

To get all the scripts to run independently.  

##Process I want done
pipe-XXX-TargDNA-Unpaired-Rclean.sh are complete processes I want 
to run on all the samples in a given directory (one script is for data I have made,
the other is for data made at WASHU).  Input argument is just the file stem.
It'll call the other two scripts here (PanelValidation.R and TruSight-Reformat.R),
to get all teh data all cleaned up after all the various steps are done.

