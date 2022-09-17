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

if [ -e ${name}.bsh ]
then
rm ${name}.bsh
echo "previous bsh removed" 
fi

cat << END >> ${name}.bsh
#PBS -l select=1:ncpus=${NPROC}:mem=2gb:scratch_local=2gb:cpu_flag=avx2
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

# Minimization
gmx_mpi_d grompp -f nma_min.mdp -c ${name}.gro -p TOPO.top -o min.tpr -maxwarn 2
gmx_mpi_d mdrun -v -deffnm min -ntomp \$PBS_NUM_PPN  -maxh 12

# Hessian calculation
gmx_mpi_d grompp -f nma.mdp -c min.gro -p TOPO.top -t min.trr -o nma.tpr -maxwarn 2
gmx_mpi_d mdrun -v -deffnm nma -ntomp \$PBS_NUM_PPN 

cp -r * $DIR || export CLEAN_SCRATCH=false
END

qsub ${name}.bsh

