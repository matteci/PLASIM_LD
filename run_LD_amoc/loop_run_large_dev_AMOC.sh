#!/bin/sh

ie=1
while [ $ie -le 9 ]; do
    yyyy=000${ie}
    k=5
    ndays=10
    endblock=18
    echo $ie $k $yyyy
    ext=${yyyy}-${k}-${ndays}-${endblock}
    sed -e "s/YYYY/${yyyy}/" -e "s/KKKK/${k}/" -e "s/NNNN/${ndays}/" -e "s/EEEE/${endblock}/" < run_large_dev.sh > run_large_dev_edited_${ext}.sh 
    sbatch -W run_large_dev_edited_${ext}.sh 

    # #
    # iem=$((${ie}-1))
    # if [ $iem -ge 1 ]; then
    # 	yyym=000${iem}
    # 	extm=${yyym}-${k}-${ndays}
    # 	rm run_large_dev_Arctic_edited_${extm}.sh
    # fi
    # #
    ie=$(($ie+1))
done

##
exit 0

