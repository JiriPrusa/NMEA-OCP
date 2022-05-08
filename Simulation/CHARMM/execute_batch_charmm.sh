#!/bin/bash
for i in {0..19}; do
    echo $i
    cd $i
    /user/jprusa/scripts/run_namd_ccr.sh prep.inp 16 12 general-compute
    cd ..
done

