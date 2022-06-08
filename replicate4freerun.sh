#!/bin/sh

# this is a joke

here=`pwd` 
year=0089

ddin=AMOC_LD_amoc_pos_ntraj100_k10_LBlock360_p1_startIDl207-y2500_r2
ddout=AMOC_LD_amoc_pos_ntraj100_k0_LBlock360_p1_startIDl207-y2500_r2_y${year}mAll

mkdir $ddout
mkdir -p $ddout/data/block_0001
mkdir -p $ddout/diag/block_0001
mkdir -p $ddout/init/block_0001
cp $ddin/init/${ddin}_init_block_${year}.tar $ddout/init/block_0001/.
cd $ddout/init/block_0001/
tar -xvf ${ddin}_init_block_${year}.tar
for ff in `ls *.${year}`; do
    ff1=${ff/k10/k0}
    ff2=${ff1/startIDl207-y2500_r2/startIDl207-y2500_r2_y${year}mAll}
    ff3=`echo $ff2 | sed "s/.${year}\$/.0001/"`
    mv $ff $ff3    
done

rm ${ddin}_init_block_${year}.tar
cd $here
mkdir -p $ddout/post/ctrlobs
mkdir -p $ddout/post/utils
mkdir -p $ddout/resampling/block_0001
mkdir -p $ddout/rest/block_0001
cp -rf $ddin/run $ddout/.
cp -rf $ddin/model $ddout/.
cp -rf $ddin/scripts $ddout/.



