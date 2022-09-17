#!/bin/bash
#run like run_grom_metacentrum [name] [jobtime]
if [[ $# -eq 0 ]] ; then
    echo 'You must provide filename! Exiting.'
    exit 0
fi

DIR=$(pwd)
dir=${PWD##*/}
NPROC=1
name=$1
NTIME=$2

if [ -e ${name}.bsh ]
then
rm ${name}.bsh
echo "previous bsh removed" 
fi

cat << END >> ${name}.bsh
#PBS -l select=1:ncpus=${NPROC}:mem=8gb:scratch_local=5gb:cpu_flag=avx2
#PBS -q default
#PBS -j oe
#PBS -l walltime=${NTIME}:00:00

export OMP_NUM_THREADS=\$PBS_NUM_PPN
trap "clean_scratch" TERM EXIT

module add gromacs-2020.3-double

cd \$SCRATCHDIR || exit 1
cp -r $DIR . || exit 2
cd $dir

DATADIR="\$PBS_O_WORKDIR"

# Diagonalization
gmx_mpi_d nmeig -s nma.tpr -f nma.mtx -first 0 -last 3000 -T 300

cp -r * $DIR || export CLEAN_SCRATCH=false
END

qsub ${name}.bsh

