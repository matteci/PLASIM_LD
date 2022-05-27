#!/bin/sh
# spdyn_to_grid inputFile outputFile

cdo="cdo -s"
format="nc4 -z zip"
cdonc="cdo -f nc -s"
cdozip="cdo -f $format -s"



$cdonc sealevelpressure -sp2gp $1 press$$.nc
$cdonc dv2uv -selvar,d,zeta $1 uv_gaussian$$.nc
$cdonc sp2gp -selvar,hus,ta,sg $1 hts_gaussian$$.nc
$cdonc sp2gp -selvar,pl $1 pl_gaussian$$.nc
$cdonc -delname,sg,ta,hus,pl,d,zeta $1 $1_grid
$cdozip merge $1_grid uv_gaussian$$.nc hts_gaussian$$.nc pl_gaussian$$.nc press$$.nc out$$.nc
$cdo ml2pl,92500,85000,70000,50000,30000,20000,10000,5000 out$$.nc $2

rm uv_gaussian$$.nc hts_gaussian$$.nc pl_gaussian$$.nc press$$.nc $1_grid out$$.nc

exit 0
