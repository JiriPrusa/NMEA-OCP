source writePWgro.tcl

proc alignTrajToTemplate {sel1 molID2} {
    set sel_text [$sel1 text]
    set sel2 [atomselect $molID2 $sel_text]
    set mol2 [atomselect $molID2 all]
    set nf [molinfo $molID2 get numframes]
    for {set i 0} {$i < $nf} {incr i 1} {
        $sel2 frame $i
        $mol2 frame $i    
	    set M [measure fit $sel2 $sel1]
    	$mol2 move $M
    }
}

proc processTraj {skip watRadius} {
    # load traj
    set molID [mol new "md.gro" type {gro} first 0 last -1 step 1 waitfor 1]
    animate delete  beg 0 end 0 skip 0 $molID
    mol addfile "center.xtc" type {xtc} first 0 last -1 step 1 waitfor -1 $molID
    # align frames
    set templID [mol new "NMA/prot_aver.pdb" type {pdb} first 0 last -1 step 1 waitfor 1]	
    set templ_sel [atomselect $templID protein]
    alignTrajToTemplate $templ_sel $molID
    cd NMA
    # iterate thru frames, write individual frames and prepare topology
    for {set i 0} {$i < 102} {incr i $skip} {
	    puts "processing frame $i ..."
    	file mkdir frame_$i
        cd frame_$i
	    set watNum [writePWgro $molID $i $watRadius frame_$i]
        file copy ../templ.top ./TOPO.top
        set fo [open TOPO.top a]
        puts $fo "SOL   $watNum"
        close $fo
        cd ..
    }
    cd ..
    mol delete $molID
}

# Call it. #1 argument is frame step, #2 argument is radius for water sphere
processTraj 10 6
exit
