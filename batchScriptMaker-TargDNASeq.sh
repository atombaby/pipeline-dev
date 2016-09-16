#!/bin/bash

samples="AML438"
count=0

for s in ${samples}; do
    count=`expr $count + 1`

    base="t${count}"
    sbatch="${base}.sbatch"

    echo "#!/bin/bash" > ${sbatch}
    echo "#SBATCH -N1" >> ${sbatch}
    echo "#SBATCH -n4" >> ${sbatch}
    echo "#SBATCH -t0-12" >> ${sbatch}
    echo "#SBATCH -o '${base}-%j.out'" >> ${sbatch}
    echo "echo 'Processing' ${s}" >> ${sbatch}
    echo "/fh/fast/paguirigan_a/TargetedDNASeq/FinishedScripts/pipe-TruSight-TargDNA-UnPaired.sh ${s}" >> ${sbatch}
done
