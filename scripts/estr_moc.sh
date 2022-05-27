#!/bin/bash

# Maximum of Atlantic Meridional Overturning Circulation (AMOC) between 46-66°N and below 700 m

EXP=l220    # Name your experiment here
YEAR1=1     # First year
YEAR2=3000  # Last year

# ------------------------------------------------------------------------------------------------------------------------------------

for (( y = YEAR1 ; y <= YEAR2 ; y++ )) ; do

    if [ $y -le 999 ]; then
       year=$(printf "%04d" $y)  # Add zeros to have 4 digits
    else
       year=$y
    fi

    
    grep "ATL max" ${EXP}_DIAG.$year.txt | cut -c30-37 > moc.txt  # Extract the column with AMOC (36 values/year)
    awk '{ total += $1; count++ } END { print total/count }' moc.txt > moc_mean.txt  # Mean of 36 values (1 value/y)    

    paste moc_mean.txt >> ${EXP}_amoc_yearmean.${YEAR2}y.txt

done

rm moc.txt moc_mean.txt 









