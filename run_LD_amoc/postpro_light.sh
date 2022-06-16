#!/bin/sh

expdir=$1
if [ $# == 0 ]; then
   expdir=/home/zappa/work/PLASIM/PLASIM-master/AMOC_LD_amoc_pos_ntraj100_k10_LBlock360_p1_startIDl207-y2500_r2/
fi
#expname=`echo expdir | rev | cut -d 1 -f / | rev`
expname=$2
blocklabel=$3
block=$4
blocknumber=`printf '%04d' ${block}`
ntraj=$5
ntrajnumber=`printf '%04d' ${ntraj}`

# remove restart files
rm ${expdir}/rest/${blocklabel}/*

# subsample init files, keep 1 every 10 years
if [ $(expr $block % 10) -eq 1 ]; then
    tar -cf ${expdir}/init/${expname}_init_${blocklabel}.tar -C ${expdir}/init/${blocklabel} .
    rm ${expdir}/init/${blocklabel}/* 
else
    rm ${expdir}/init/${blocklabel}/* 
fi
# compute ensemble mean across all members for all data types
arr=("lsg" "data" "ice" "ocean")
for ii in "${arr[@]}"; do
    
    cdo ensmean ${expdir}/data/${blocklabel}/netcdf/${expname}_${ii}.*.${blocknumber}.nc ${expdir}/data/${blocklabel}/netcdf/${ii}.${blocknumber}.nc
done
    
# sub-selection of variables from individual members. This is done in merged files. We could evalute if it is convenient to sub selects variables in members files.

for aa in $(seq -w 1 ${ntrajnumber}) ; do
    for ii in "${arr[@]}"; do
	if [ ${ii} = "lsg" ]; then
	    
	    var1=psi,fluwat
	    lev1=1

	    varf=utot,vtot,convad,s,t
	    levf=75,550,2250

	    varh=w
	    levh=1025

            cdo -f nc4 -z zip -sellevel,$lev1,$levf,$levh  -selvar,$var1,$varf,$varh ${expdir}/data/${blocklabel}/netcdf/${expname}_${ii}.${aa}.${blocknumber}.nc   ${expdir}/data/${blocklabel}/netcdf/${expname}_${ii}.${aa}.${blocknumber}_light.nc
	    rm  ${expdir}/data/${blocklabel}/netcdf/${expname}_${ii}.${aa}.${blocknumber}.nc

	    
	elif [ ${ii} = "data" ]; then
	    
	    var1=tas,psl,tauu,tauv
	    lev1=0

	    varf=u,v,ta
	    levf=85000,30000



            cdo -f nc4 -z zip -sellevel,$lev1,$levf  -selvar,$var1,$varf ${expdir}/data/${blocklabel}/netcdf/${expname}_${ii}.${aa}.${blocknumber}.nc   ${expdir}/data/${blocklabel}/netcdf/${expname}_${ii}.${aa}.${blocknumber}_light.nc
	    rm  ${expdir}/data/${blocklabel}/netcdf/${expname}_${ii}.${aa}.${blocknumber}.nc
	    
	    
	elif [ ${ii} = "ocean" ]; then
	    var1=heata,sst
	    cdo -f nc4 -z zip   -selvar,$var1 ${expdir}/data/${blocklabel}/netcdf/${expname}_${ii}.${aa}.${blocknumber}.nc   ${expdir}/data/${blocklabel}/netcdf/${expname}_${ii}.${aa}.${blocknumber}_light.nc
	    rm  ${expdir}/data/${blocklabel}/netcdf/${expname}_${ii}.${aa}.${blocknumber}.nc




	    
	elif [ ${ii} = "ice" ]; then
	    var1=icec,iced

            cdo -f nc4 -z zip  -selvar,$var1 ${expdir}/data/${blocklabel}/netcdf/${expname}_${ii}.${aa}.${blocknumber}.nc   ${expdir}/data/${blocklabel}/netcdf/${expname}_${ii}.${aa}.${blocknumber}_light.nc
	    rm  ${expdir}/data/${blocklabel}/netcdf/${expname}_${ii}.${aa}.${blocknumber}.nc
	fi
done
done




tar -cf ${expdir}/data/${expname}_data_${blocklabel}.tar -C ${expdir}/data/${blocklabel}/netcdf/ .
rm ${expdir}/data/${blocklabel}/*.${blocknumber}
rm ${expdir}/data/${blocklabel}/netcdf/*

tar -cf ${expdir}/diag/${expname}_diag_${blocklabel}.tar -C ${expdir}/diag/${blocklabel} .
rm ${expdir}/diag/${blocklabel}/*

tar -cf ${expdir}/resampling/${expname}_resampling_${blocklabel}.tar -C ${expdir}/resampling/${blocklabel} .
       rm ${expdir}/resampling/${blocklabel}/*

  


