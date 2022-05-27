#!/bin/sh

expdir=$1
if [ $# == 0 ]; then
   expdir=/home/zappa/work/PLASIM/PLASIM-master/AMOC_LD_amoc_pos_ntraj100_k10_LBlock360_p1_startIDl207-y2500_r2/
fi
expname=`echo expdir | rev | cut -d 1 -f / | rev`

# remove restart files


# subsample init files, keep 1 every 10 years


# compute ensemble mean across all memebers for all data types


# sub-select variables from individual members
dirtest=/home/zappa/work/PLASIM/PLASIM-master/AMOC_LD_amoc_pos_ntraj100_k10_LBlock360_p1_startIDl207-y2500_r2/data/
filelsg=AMOC_LD_amoc_pos_ntraj100_k10_LBlock360_p1_startIDl207-y2500_r2_lsg.0010.0125.nc


fileslsg=`ls $expdir/data/${expname}_lsg `

## LSG
var1=psi,sice
lev1=1

varf=utot,vtot,convad,s,t
levf=75,550,2250

varh=w
levh=1025

cdo -f nc4 -z zip -sellevel,$lev1,$levf,$levh  -selvar,$var1,$varf,$varh $ff prova.nc

