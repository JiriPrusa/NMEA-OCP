#!/bin/bash
if [[ $# -eq 0 ]] ; then
    echo 'Error! No filename prefix. Exiting.'
    exit 0
fi

prefix=$1

for i in {0..19}; do
    mkdir $i
    cd $i
    out_name=$(printf "%s_%d" $prefix $i)  
    gro_name=$(printf "%s_%d.gro" $prefix $i) 
    # copy input files
    cp -r ../par .
    cp ../INP/* .
    cp ../GRO/$gro_name .
    # make input structure
    vmd -dispdev none -e ../generateStructure.tcl -args $out_name
    # prepare output folders
    mkdir eq_out
    mkdir output_npt
    cd ..
done
        
