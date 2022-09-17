proc writePWgro {molid frameNum radius nFname} {
    set r $radius
    # First select the water layer
    set watLayerSel [atomselect $molid "water within $r of protein" frame $frameNum]
    # Make sure we only take whole water molecules
    set indexes [$watLayerSel get index]
    set goodIndexes {}
    set lRes -1
    foreach index $indexes {
	    set msel [atomselect $molid "index $index" frame $frameNum]
	    set mresid [$msel get resid]
	    if {$mresid != $lRes} {
		    set gI {}
		    lappend gI $index
	    } else {
		    lappend gI $index
		    if { [llength $gI] == 3 } {
			    lappend goodIndexes $gI
			    set gI {}
		    }	
	    }
	    set lRes $mresid 

    }
    set iI {}
    foreach indList $goodIndexes {
	    foreach ind $indList {
		    lappend iI $ind	
	    }
    }
    # Now make the selection and write the pdb
    set sel [atomselect $molid "protein or resname CAN ASN or index $iI" frame $frameNum]
    $sel writegro ${nFname}.gro
    set watNum [expr [llength $iI] / 3]
    puts "Protein and water within $r radius from frame $frameNum written to file ${nFname}.gro. Totaly [$sel num] atoms ($watNum waters)."
    # Return number of water molecules  
    return $watNum
}
