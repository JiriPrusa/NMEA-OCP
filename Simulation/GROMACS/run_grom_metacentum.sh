#!/bin/bash
#run like run_grom_metacentrum [name] [jobtime]
if [[ $# -eq 0 ]] ; then
    echo 'You must provide filename! Exiting.'
    exit 0
fi

DIR=$(pwd)
dir=${PWD##*/}
NPROC=4
name=$1
NTIME=$2

maxtime=$(expr $NTIME - 1)
if [ -e ${name}.bsh ]
then
rm ${name}.bsh
echo "previous bsh removed" 
fi

cat << END >> ${name}.bsh
#PBS -l select=1:ncpus=${NPROC}:ngpus=1:mem=8gb:scratch_local=8gb:cluster=^doom
#PBS -q gpu_long
#PBS -j oe
#PBS -l walltime=${NTIME}:00:00

export OMP_NUM_THREADS=\$PBS_NUM_PPN
trap "clean_scratch" TERM EXIT

module add gromacs-2018.6-gpu-mpi

cd \$SCRATCHDIR || exit 1
cp -r $DIR . || exit 2
cd $dir

DATADIR="\$PBS_O_WORKDIR"

# Minimization
gmx_mpi grompp -f min.mdp -c $name -p OCP.top -o min.tpr
gmx_mpi mdrun -v -deffnm min -ntomp \$PBS_NUM_PPN 

# Eq. nvt_0 (30K, 10ps)
gmx_mpi grompp -f 0_nvt.mdp -c min.gro -r min.gro -p OCP.top -o 0_nvt.tpr
gmx_mpi mdrun -deffnm 0_nvt -ntomp \$PBS_NUM_PPN

# Eq. npt_1 (30K->300K, 50ps)
gmx_mpi grompp -f 1_npt.mdp -c 0_nvt.gro -r 0_nvt.gro -t 0_nvt.cpt -p OCP.top -o 1_npt.tpr
gmx_mpi mdrun -deffnm 1_npt -ntomp \$PBS_NUM_PPN

# Eq. npt_2 (300K, 500ps)
gmx_mpi grompp -f 2_npt.mdp -c 1_npt.gro -r 1_npt.gro -t 1_npt.cpt -p OCP.top -o 2_npt.tpr
gmx_mpi mdrun -deffnm 2_npt -ntomp \$PBS_NUM_PPN

# Production run
gmx_mpi grompp -f md.mdp -c 2_npt.gro -r 2_npt.gro -t 2_npt.cpt -p OCP.top -o md.tpr
gmx_mpi mdrun -deffnm md -ntomp \$PBS_NUM_PPN -maxh $maxtime

cp -r * $DIR || export CLEAN_SCRATCH=false
END

qsub ${name}.bsh

