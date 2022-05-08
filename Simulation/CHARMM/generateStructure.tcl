proc centerMolecule {selection} {
$selection moveby [vecinvert [measure center $selection]]
}

#################################################################
proc generateInitialBox {fName} {
    set input_gro "${fName}.gro"
    set outname $fName
    set box_vec {84.0 84.0 84.0 90.0 90.0 90.0}

    # Read input structure and create topo
    package require psfgen
    resetpsf
    topology ../toppar/top_all36_prot.rtf
    topology ../toppar/top_all36_lipid.rtf
    topology ../toppar/top_all36_carb.rtf
    topology ../toppar/top_all36_cgenff.rtf
    topology ../toppar/toppar_water_ions_namd.str
    topology ../toppar/ech_ed.rtf

    set molID [mol new $input_gro]
    set CAN [atomselect $molID "resname CAN"]
    set OCP [atomselect $molID "not resname CAN"]
    $CAN set resname "ECH"
    $CAN set chain "C"
    $OCP set chain "A"
    $CAN writepdb CAN_seg.pdb
    $OCP writepdb OCP_seg.pdb

    pdbalias atom ECH C07 C25
    pdbalias atom ECH C03 C30
    pdbalias atom ECH C05 C29
    pdbalias atom ECH C09 C28
    pdbalias atom ECH C17 C27
    pdbalias atom ECH O01 O
    pdbalias atom ECH C15 C26
    pdbalias atom ECH C21 C38
    pdbalias atom ECH C19 C24
    pdbalias atom ECH C23 C23
    pdbalias atom ECH C25 C22
    pdbalias atom ECH C27 C37
    pdbalias atom ECH C29 C21
    pdbalias atom ECH C31 C20
    pdbalias atom ECH C33 C19
    pdbalias atom ECH C35 C18
    pdbalias atom ECH C39 C36
    pdbalias atom ECH C37 C17
    pdbalias atom ECH C41 C16
    pdbalias atom ECH C42 C15
    pdbalias atom ECH C38 C14
    pdbalias atom ECH C36 C13
    pdbalias atom ECH C40 C35
    pdbalias atom ECH C34 C12
    pdbalias atom ECH C32 C11
    pdbalias atom ECH C30 C10
    pdbalias atom ECH C26 C9
    pdbalias atom ECH C28 C34
    pdbalias atom ECH C24 C8
    pdbalias atom ECH C20 C7
    pdbalias atom ECH C08 C6
    pdbalias atom ECH C04 C1
    pdbalias atom ECH C13 C31
    pdbalias atom ECH C14 C32
    pdbalias atom ECH C06 C2
    pdbalias atom ECH C10 C3
    pdbalias atom ECH C18 C4
    pdbalias atom ECH C16 C5
    pdbalias atom ECH C22 C33
    pdbalias atom ECH O02 O2
    pdbalias atom ECH C11 C40
    pdbalias atom ECH C12 C39

    segment C {pdb CAN_seg.pdb}
    segment A {pdb OCP_seg.pdb}

    coordpdb CAN_seg.pdb C
    coordpdb OCP_seg.pdb A

    guesscoord

    writepdb $outname.pdb
    writepsf $outname.psf

    mol delete $molID

    # Add box 
    package require pbctools
    set halfbox [vecscale [lrange $box_vec 0 2] 0.5]
    set molid [mol new $outname.pdb]
    set sel [atomselect $molid all]
    centerMolecule $sel
    $sel moveby $halfbox
    pbc set $box_vec
    $sel writepdb $outname.pdb
    mol delete $molid

    # Solvate
    package require solvate
    solvate $outname.psf $outname.pdb -minmax [list {0 0 0} [lrange $box_vec 0 2]] -o ${outname}_solv

    # Add ions
    package require autoionize
    autoionize -psf ${outname}_solv.psf -pdb ${outname}_solv.pdb -nions {{SOD 60} {CLA 53}} -o start

    # Prepare restraint files
    set sel [atomselect top all]
    $sel set beta 0.0
    set cas [atomselect top "name CA"]
    $cas set beta 1.0
    $sel writepdb restraints.pdb

    $sel set beta 0.0
    set bb [atomselect top "backbone"] 
    $bb set beta 1.0
    $sel writepdb fixed_backbone.pdb
}
puts $argv
eval generateInitialBox $argv
quit

###################################################


