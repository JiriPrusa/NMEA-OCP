#!/bin/bash
if [[ $# -eq 0 ]] ; then
    echo 'Error! No filename prefix. Exiting.'
    exit 0
fi

module load gromacs-2018.6-gpu-mpi 

prefix=$1

for i in {0..19}; do
    mkdir $i
    cd $i
    gro_name=$(printf "%s_%d.gro" $prefix $i)    
    # copy input files
    cp ../MDP/* .
    cp ../ITP/* .
    cp ../GRO/$gro_name .
    # make box
    gmx_mpi editconf -f $gro_name -o boxed.gro -c -bt cubic -box 8.4 8.4 8.4
    # solvate 
    gmx_mpi solvate -cp boxed.gro -cs spc216.gro -o solvated.gro -p OCP.top
    # add ions
    gmx_mpi grompp -f ions.mdp -c solvated.gro -p OCP.top -o ions.tpr
    echo 15 | gmx_mpi genion -s ions.tpr -o input_${prefix}_${i}.gro -p OCP.top -pname NA -nname CL -np 60 -nn 53 
    cd ..
done
        
