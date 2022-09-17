# iterate over trajectories
for i in {0..19}
do
  cd $i
  echo $i
  if [ ! -d "NMA" ]; then
    echo "NMA directory does not exist!!!" 
    exit
  fi
  cp ../MDP/nma_min.mdp NMA/.
  cp ../MDP/nma.mdp NMA/.
  cd NMA
  # iterate over frames
  for dir in */
  do
    cd $dir
    echo "  $dir"
    cp ../nma_min.mdp .
    cp ../nma.mdp .
    name=${dir%*/}
    run_nma_metacentum.sh $name 2
    cd ..
  done     
  cd ..
  cd ..
done
