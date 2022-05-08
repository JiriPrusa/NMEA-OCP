#!/bin/bash
#run like run_namd_ccr [input_file] [nproc] [walltime] [partition]
if [[ $# -ne 4 ]] ; then
    echo 'Error: Not enough arguments. Run like: run_namd_ccr [input_file] [nproc] [walltime] [partition]'
    exit 0
fi

# Define NAMD homedir!
NAMDHOME="/user/jprusa/NAMD3_a8"

INFILE=$1
NPROC=$2
NTIME=$3
PARTITION=$4
LOGFILE=${INFILE}.log

if [ -e ${INFILE}.bsh ]
then
rm ${INFILE}.bsh
echo "previous bsh removed"
fi

cat << END >> ${INFILE}.bsh
#!/bin/bash
#SBATCH --time=${NTIME}:00:00
#SBATCH --output=SLURM_NAMD.out
#SBATCH --error=SLURM_NAMD.err
#SBATCH --job-name=NAMD_${INFILE}
#SBATCH --partition=${PARTITION}
#SBATCH --mem=4000
#SBATCH --nodes=1
#SBATCH --tasks-per-node=${NPROC}
#SBATCH --gres=gpu:1

cd \$SLURM_SUBMIT_DIR

$NAMDHOME/charmrun +p${NPROC} $NAMDHOME/namd3 +idlepoll +devices 0 $INFILE >& $LOGFILE

END

sbatch ${INFILE}.bsh

