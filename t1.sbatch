#!/bin/bash
#SBATCH -N1
#SBATCH -n4
#SBATCH -t0-12
#SBATCH -o 't1-%j.out'
#SBATCH -e 't1-%j.out'
echo 'Processing' 1005-007
/fh/fast/paguirigan_a/TargetedDNASeq/FinishedScripts/pipe-TruSight-TargDNA-UnPaired-Rclean.sh 1005-007
