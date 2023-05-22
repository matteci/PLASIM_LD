#!/bin/bash
#


#iy=2498
#stepy=2
#nstep=8
arr=("30" "40" "50" "60" "70" "80" "90" "100" "110" )

#totrange=$(($stepy*$nstep))
#fy=$((${iy}-${totrange}))

echo "totrange: $totrange"

echo "fy: ${fy}"


#for yy in $(seq -w ${fy} ${stepy} ${iy}); do
for yy in "${arr[@]}"; do      
    echo "current star"
    echo ${yy}
    sed -i "s/initblock=.*/initblock=${yy}/" run_large_dev_LD_Singlerecorecursive.sh 
    sbatch --wait ./run_large_dev_LD_Singlerecorecursive.sh
    wait
    
    
   

done

echo "end simuation"
exit 0
   
      
