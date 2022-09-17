module add vmd-1.9.3
module add gromacs-2020.3-gpu-mpi

for i in {0..19}
do
  cd $i
  mkdir NMA
  cp ../ITP/templ.top NMA/.
  cp ../prot_aver.pdb NMA/.
  echo 1 0 | gmx_mpi trjconv -f md.trr -s md.tpr -o center.xtc -center -pbc mol
  vmd -e ../processTraj.tcl -dispdev text
  cd ..
done
