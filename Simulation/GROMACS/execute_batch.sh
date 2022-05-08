#!/bin/bash
if [[ $# -eq 0 ]] ; then
    echo 'Error! No filename prefix. Exiting.'
    exit 0
fi

prefix=$1

for i in {0..19}; do
    cd $i
    gro_name=$(printf "input_%s_%d.gro" $prefix $i)    
    /storage/brno3-cerit/home/prusaj/scripts/run_grom_metacentum.sh $gro_name 336
    cd ..
done
