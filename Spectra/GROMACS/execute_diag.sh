# iterate over trajectories
for i in {0..19}
do
  cd $i
  echo $i
  if [ ! -d "NMA" ]; then
    echo "NMA directory does not exist!!!"
    cd .. 
    continue
  fi
  cd NMA
  # iterate over frames
  for dir in */
  do
    cd $dir
    echo "  $dir"
    if [ ! -f "nma.mtx" ]; then
      echo "Hessian not available!!!"
      cd ..
      continue
    fi
    name=${dir%*/}
    run_diag_metacentrum.sh ${name}_diag 168
    cd ..
  done     
  cd ..
  cd ..
done

