#!/bin/sh
#
#SBATCH -J PLASIM-large-dev_%j
#SBATCH --time=00:05:00
#SBATCH --nodes=1
#SBATCH --ntasks=5
#SBATCH --ntasks-per-node=5
#SBATCH --output=PLASIM-large-dev_%j.log
#SBATCH --error=PLASIM-large-dev_%j.log 
#SBATCH --partition=batch

##### LOAD PYTHON VIRTUAL ENVIRONMENT WITH MODULES: numpy, math, netCDF4
#source $HOME/my_venv/bin/activate

#set -xv

# -D: Changing script to create ensembles adding noise only at restart.

#### NAMELIST ##############################################################
nameThisFile='run_large_dev'
expname="AMOC_LD_amoc_abs_ntraj50_k10_LBlock360_p1_startIDy200-0008_l201-0001"
#
# Parameters controlling length of experiment
newexperiment=0  # 1: nuovo

initblock=41     # block è periodo lungo come resampling. 
endblock=41      # ultimo blocco: ti definisce lunghezza integrazione

# Parameters controlling resampling, observable and weights
varname='amoc'    # variabile usata per resampling
domain='DIAG'     # domain in PLASIM output of varname
resamplingname='resampling_Amoc.py'   # file che fa il resampling
ntrajs=5
k=0
NMonths=2   # length resampling block
NDays=0     # length resampling block
LYear=360   # 
startID=y200-0008_l201-0001  # 0BCD (B: ocean state, C: atmospheric state, D: repeat)

# Refine experiment name
expname=${expname/VARNAME/${varname}}

# Parameters controlling cores used by PLASIM in each run
nparallel=1 # cores usati da PLASIM. with nparallel=2 there are memory problems, now fixed at 8, try 4 one day.
#
# Directory names
scriptdir=`pwd`
homedir='/work/users/zappa/PLASIM/PLASIM-master'
modeldir=${homedir}/plasim/run # cartella con eseguibili di PLASIM compilato per processori con namelist etc
modelname=`printf 'most_plasim_t21_l10_p%d.x' ${nparallel}` # nome eseguibile
# 
# Parameters controlling dubug
debug=0
#
# Restart file info (if new experiment)
sourcerestdir=/work/users/zappa/PLASIM/PLASIM-master/AMOC_CTRL_amoc_abs_ntraj10_k0_LBlock360_p1_startIDl201-0001/rest/
plasimrestname=AMOC_CTRL_amoc_abs_ntraj10_k0_LBlock360_p1_startIDl201-0001_rest.0008.0200
lsgrestname=AMOC_CTRL_amoc_abs_ntraj10_k0_LBlock360_p1_startIDl201-0001_lsgrest.0008.0200


##############################################################################

echo "nodes"
echo ${SLURM_NODES}
echo "tasks"
echo ${SLURM_NTASKS}
echo "cpu-per-task"
echo ${SLURM_CPU_PER_TASK}
echo "mem-per-cpu"
echo ${SLURM_MEM_PER_CPU}
echo "mem"
echo ${SLURM_MEM}

###### INITIALISATION ############
# prepare plasim_namelist
KR=1
sed  -e "s/LYear/${LYear}/" -e "s/NMonths/${NMonths}/" -e "s/NDays/${NDays}/" -e "s/kick/${KR}/" \
     plasim_namelist0 > ${modeldir}/plasim_namelist 

# determine dt parameter for resamplying
TotDaysBlock=$((${NDays}+${NMonths}*30))
NBlocks=$((${endblock}-${initblock}+1))
TotDaysRun=$((${NBlocks} * ${TotDaysBlock}))
dt=`echo "scale=5;${NDays}/${LYear}" | bc`

if [ $newexperiment == 0 ]; then # cleaner to just remove TotDaysRun from expname
    TotDaysRun=$((${endblock} * ${TotDaysBlock}))
fi

# update expname to include parameter setting
expname=${expname}_ntraj${ntrajs}_k${k}_LBlock${TotDaysBlock}_p${nparallel}_startID${startID}


#note that the number of tasks must be chosen so that SLURM_NTASKS/NPARALLEL is an integer
ntrajsperbatch=$((${SLURM_NTASKS}/${nparallel})) # quante traiettorie ogni batch (diverso da batch sul filename che si riferisce a pool condizioni iniziali)
nbatches=$((${ntrajs}/${ntrajsperbatch})) # numero volte che devi integrare per finare # members
ntrajrest=$((${ntrajs}-(${nbatches}*${ntrajsperbatch}))) # traiettorie in ultimo batch

if [ ${ntrajrest} -gt 0 ]; then nbatches=$(( ${nbatches}+1 )); fi
mem=0

## nomi di scripts dentro 
launchname=`printf 'run_large_dev_%s' ${expname}`   # launchname è se stesso (after reneame)
createinitname='create_initial_conditions_simple' # scripts che definisce condizioni iniziale dell'ensemble 
organizename='organize_output_new' # organizza traiettorie al termine di ogni block
extractname='extract_observable' # estrae osservabile per definire i pesi
maskname='most_t42_lsmask.nc'    # land sea mask (dentro model dir)
gpareaname='most_t42_gparea.nc'  # area griglia (dentro model dir)
reconstructname='reconstruct.py'

# define experiment folders 
expdir=`printf '%s/%s' ${homedir} ${expname}`
runexpdir=`printf '%s/run' ${expdir}`   # numero di cartelle per ogni run parallelo 
dataexpdir=`printf '%s/data' ${expdir}` # output del modello
restexpdir=`printf '%s/rest' ${expdir}` # restart stessi a fine run
initexpdir=`printf '%s/init' ${expdir}` # restart dopo resampling: resampling mischi i restart files
diagexpdir=`printf '%s/diag' ${expdir}` # diagnostiche di PLASIM
postexpdir=`printf '%s/post' ${expdir}` # all'inizio nulla 
resamplingexpdir=`printf '%s/resampling' ${expdir}` # informazioni su come è stato fatto il resampling: contiene file python con info
scriptsexpdir=`printf '%s/scripts' ${expdir}` # 
modelexpdir=`printf '%s/model' ${expdir}` # dove viene fatto girare esperimento

# # define burner stuff
# burnerdir='/home/fragone/PLASIM-master/postprocessor'
# burnername='burn7.x'
# namelistfolder='/home/fragone/PLASIM-master/postprocessor'
# namelistname='test_ts.nl' # namelist per estrarre variabile
# burnerexpdir=`printf '%s/burner' ${expdir}`  

# if this is a brand new simulation, create folders
if [ ${newexperiment} -eq 1 ] 
then
  # start creating folder structure
  echo "$(date +"%Y-%m-%d %T") started creating folders"
  # create mother folders
  mkdir -p ${expdir}
  mkdir -p ${runexpdir}
  mkdir -p ${dataexpdir}
  mkdir -p ${restexpdir}
  mkdir -p ${initexpdir}
  mkdir -p ${diagexpdir}
  mkdir -p ${postexpdir}
  mkdir -p ${postexpdir}/ctrlobs
  mkdir -p ${postexpdir}/utils
  mkdir -p ${resamplingexpdir}
  mkdir -p ${scriptsexpdir}
  mkdir -p ${modelexpdir}
#  mkdir -p ${burnerexpdir}
  # copy stuff in experiment folder
  cp ${scriptdir}/${nameThisFile}.sh ${scriptsexpdir}/${launchname}
  cp ${scriptdir}/${createinitname} ${scriptsexpdir}/${createinitname}
  cp ${scriptdir}/${organizename} ${scriptsexpdir}/${organizename}
  cp ${scriptdir}/${extractname} ${scriptsexpdir}/${extractname}
  cp ${scriptdir}/${resamplingname} ${scriptsexpdir}/${resamplingname}
  cp ${scriptdir}/${reconstructname} ${scriptsexpdir}/${reconstructname}
  cp ${modeldir}/* ${modelexpdir}/.
  cp ${homedir}/data/${maskname} ${postexpdir}/utils/${maskname}     # mask
  cp ${homedir}/data/${gpareaname} ${postexpdir}/utils/${gpareaname} # aree
  # handle burner stuff
#  cp ${burnerdir}/${burnername} ${burnerexpdir}/${burnername}
#  cp ${namelistfolder}/${namelistname} ${burnerexpdir}/${namelistname}
  # create run folders for each trajectory per batch
  traj=1
  while [ ${traj} -le ${ntrajsperbatch} ]
  do
    runtrajdir=`printf 'run_%04d' ${traj}` 
    mkdir -p ${runexpdir}/${runtrajdir}
    cp ${modeldir}/* ${runexpdir}/${runtrajdir}/.
    traj=`expr ${traj} + 1`
  done
fi

# create folders for all blocks, plus the one after the last one (to store the init files)
if [ ${newexperiment} -eq 1 ] 
then 
  block=${initblock}
else
  block=`expr ${initblock} + 1`
fi
nextendblock=`expr ${endblock} + 1`
while [ ${block} -le ${nextendblock} ]
do
  # create folders for current block
  blockdir=`printf 'block_%04d' ${block}`
  mkdir -p ${dataexpdir}/${blockdir}
  mkdir -p ${initexpdir}/${blockdir}
  mkdir -p ${restexpdir}/${blockdir}
  mkdir -p ${diagexpdir}/${blockdir}
  mkdir -p ${resamplingexpdir}/${blockdir}
  block=`expr ${block} + 1`
done
echo "$(date +"%Y-%m-%d %T") finished creating folders"
# finished creating folder structure

# move to the scripts folders
cd ${scriptsexpdir}

# ### FIX INITIAL CONDITION ### 
 # if this is a brand new simulation, copy the initial conditions for the first block (here include some spinup if needed)
if [ ${newexperiment} -eq 1 ]
then
    batch=1
    trajinit=1
    trajend=${ntrajs}
    ./${createinitname} ${sourcerestdir} ${plasimrestname} ${lsgrestname} ${expdir} ${expname} ${trajinit} ${trajend} ${initblock}
fi
####### END INITIALISATION #############################

####### RUN SIMULATIONS  ############################### 
# start loop on time blocks
block=${initblock}
while [ ${block} -le ${endblock} ]
do
  blockdir=`printf 'block_%04d' ${block}`
  echo "$(date +"%Y-%m-%d %T") started running block ${block}"

  # start loop on batches of trajectories
  batch=1
  while [ ${batch} -le ${nbatches} ]  
  do
    # run the trajectories in the current batch
    echo "$(date +"%Y-%m-%d %T") started running batch ${batch} of block ${block}"
    traj=`expr ${batch} - 1`; traj=`expr ${traj} \* ${ntrajsperbatch}`; traj=`expr ${traj} + 1`
    if [ ${batch} -lt ${nbatches}  ]
    then
      endtraj=`expr ${batch} \* ${ntrajsperbatch}`
    else
      endtraj=${ntrajs}
    fi
    while [ ${traj} -le ${endtraj} ]
    do  
      initname=`printf '%s_init.%04d.%04d' ${expname} ${traj} ${block}` # file init per traiettoria che fai girare
      lsginitname=`printf '%s_lsginit.%04d.%04d' ${expname} ${traj} ${block}` # file init per traiettoria che fai girare
      
      trajrun=`expr ${batch} - 1`; trajrun=`expr ${trajrun} \* ${ntrajsperbatch}`; trajrun=`expr ${traj} - ${trajrun}`;
      runtrajdir=`printf 'run_%04d' ${trajrun}`
      cp ${initexpdir}/${blockdir}/${initname} ${runexpdir}/${runtrajdir}/plasim_restart # impostalo come restart
      cp ${initexpdir}/${blockdir}/${lsginitname} ${runexpdir}/${runtrajdir}/kleiin1     # impostalo come restart


      
      cd ${runexpdir}/${runtrajdir}
#      srun --mpi=pmi2 -K1 --resv-ports --exclusive --nodes=1 --ntasks=${nparallel} --mem=${mem} ${modelname} & # fai partire modello
      ./${modelname} & # fai partire modello

      if [ ${debug} -eq 1 ]; then echo "$(date +"%Y-%m-%d %T") started traj ${traj}"; fi
      traj=`expr ${traj} + 1`
    done
    wait
    echo "$(date +"%Y-%m-%d %T") finished running batch ${batch} of block ${block}"
    # all the runs in the current batch are completed 
    cd ${scriptsexpdir}

    # organize the output
    echo "$(date +"%Y-%m-%d %T") started organizing output for batch ${batch} of block ${block}"
    traj=`expr ${batch} - 1`; traj=`expr ${traj} \* ${ntrajsperbatch}`; traj=`expr ${traj} + 1`
    if [ ${batch} -lt ${nbatches}  ]
    then
      endtraj=`expr ${batch} \* ${ntrajsperbatch}`
    else
      endtraj=${ntrajs}
    fi
    while [ ${traj} -le ${endtraj} ]
    do
      trajrun=`expr ${batch} - 1`; trajrun=`expr ${trajrun} \* ${ntrajsperbatch}`; trajrun=`expr ${traj} - ${trajrun}`;
      ./${organizename} ${expdir} ${expname} ${trajrun} ${traj} ${block} & 
      #      srun --mpi=pmi2 -K1 --resv-ports --exclusive --nodes=1 --ntasks=1 --mem=${mem} ./${organizename} ${expdir} ${expname} ${trajrun} ${traj} ${block} & # sottomette per organizzare output dei runs
      if [ ${debug} -eq 1 ]; then echo "$(date +"%Y-%m-%d %T") started organizing output of traj ${traj} of block ${block}"; fi
      traj=`expr $traj + 1`
    done
    wait
    echo "$(date +"%Y-%m-%d %T") finished organizing output for batch ${batch} of block ${block}"
    # the output of the current batch is organized

    # extract the observable used in the definition of the weights of the current batch
    echo "$(date +"%Y-%m-%d %T") started extracting control observable for batch ${batch} of block ${block}"
    traj=`expr ${batch} - 1`; traj=`expr ${traj} \* ${ntrajsperbatch}`; traj=`expr ${traj} + 1`
    if [ ${batch} -lt ${nbatches}  ]
    then
      endtraj=`expr ${batch} \* ${ntrajsperbatch}`
    else
      endtraj=${ntrajs}
    fi
    while [ ${traj} -le ${endtraj} ]
    do
	./${extractname} ${expdir} ${expname} ${traj} ${block} ${varname} ${domain} & # sottomette estrazione variabile 
	#srun --mpi=pmi2 -K1 --resv-ports --exclusive --nodes=1 --ntasks=1 --mem=${mem} ./${extractname} ${expdir} ${expname} ${traj} ${block} & # sottomette estrazione variabile da osservare
      if [ ${debug} -eq 1 ]; then echo "$(date +"%Y-%m-%d %T") started extracting control observable of traj ${traj} of block ${block}"; fi
      traj=`expr $traj + 1`
    done
    wait
    echo "$(date +"%Y-%m-%d %T") finished extracting control observable for batch ${batch} of block ${block}"
    # the observable used in the definition of the weights of the current batch is extracted
    batch=`expr $batch + 1`
  done
  # end loop on batches of trajectories
  
  ### FINE SIMULAZIONE PRIMO BLOCCO ###
  ### FAI RESAMPLING PRIMA DI INIZIARE PROSSIMO BLOCCO
  # compute the weights, save the informations about the resampling and swap the restart files
  python3 -t ${resamplingname} ${expdir} ${expname} ${ntrajs} ${block} ${varname} ${k} ${dt} ${maskname} ${gpareaname}  

  blocklabel=`printf 'block_%04d' ${block}`
  blocknumber=`printf '%04d' ${block}`

  ## postprocess to netcdf ##
  mkdir -p ${expdir}/data/${blocklabel}/netcdf/
  for a in `ls ${expdir}/data/${blocklabel}/*.${blocknumber}`; do 
      fname=`echo $a | rev | cut -d / -f 1 | rev`
      ${homedir}/scripts/srv2nc -m -p ${a} ${expdir}/data/${blocklabel}/netcdf/${fname}.nc &
  done
  wait
  ## ## ## ## ## ##

  tar -cf ${expdir}/diag/${expname}_diag_${blocklabel}.tar -C ${expdir}/diag/${blocklabel} .
  rm ${expdir}/diag/${blocklabel}/*
  tar -cf ${expdir}/resampling/${expname}_resampling_${blocklabel}.tar -C ${expdir}/resampling/${blocklabel} .
  rm ${expdir}/resampling/${blocklabel}/*
  tar -cf ${expdir}/init/${expname}_init_${blocklabel}.tar -C ${expdir}/init/${blocklabel} .
  rm ${expdir}/init/${blocklabel}/*
  tar -cf ${expdir}/rest/${expname}_rest_${blocklabel}.tar -C ${expdir}/rest/${blocklabel} .
  rm ${expdir}/rest/${blocklabel}/*
  tar -cf ${expdir}/data/${expname}_data_${blocklabel}.tar -C ${expdir}/data/${blocklabel}/netcdf/ .
  rm ${expdir}/data/${blocklabel}/*.${blocknumber}
  rm ${expdir}/data/${blocklabel}/netcdf/*
  blocknumber=`printf '%04d' ${block}`
  cd ${expdir}/post/ctrlobs
  if [ $domain == DIAG ]; then
      tar cf ${expname}_ctrlobs_${blocklabel}.tar ${expname}_ctrlobs.*.${blocknumber}.txt
      rm ${expname}_ctrlobs.*.${blocknumber}.txt
  else
      tar cf ${expname}_ctrlobs_${blocklabel}.tar ${expname}_ctrlobs.*.${blocknumber}.nc
      rm ${expname}_ctrlobs.*.${blocknumber}.nc
      tar cf ${expname}_burn_ctrlobs_log_${blocklabel}.tar ${expname}_burn_ctrlobs.*.${blocknumber}.log
      rm ${expname}_burn_ctrlobs.*.${blocknumber}.log
  fi
  
  # Adjust kickrestart to zero if running unperturbed ensemble
  if [[ $k == 0 && ${block} -eq 1 ]]; then
      for f in `ls ${expdir}/run/run_*/plasim_namelist`; do
	  sed  -e "s/LYear/${LYear}/" -e "s/NMonths/${NMonths}/" -e "s/NDays/${NDays}/" -e "s/kick/0/" \
	       ${scriptdir}/plasim_namelist0 > ${f}
      done
  fi
  
  block=`expr $block + 1`
done
mv ${scriptdir}/PLASIM-large-dev_${SLURM_JOB_ID}.log ${expdir}/. ## COPIA FILE LOG DENTRO CARTELLA ESPERIMENTO

### EXPERIMENT COMPLETED
### NOW SUBMIT NEW PROCESS TO RECONSTRUCT THE TRAJECTORIES

SLURM_JOB_ID_PARENT=${SLURM_JOB_ID}
cat << EOT > ${scriptdir}/run_PLASIM-large-dev-resample_${SLURM_JOB_ID_PARENT}.sh
#!/bin/sh

#SBATCH -J PLASIM-large-dev-resample_%j
#SBATCH --time=00:10:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --output=PLASIM-large-dev-resample_%j.log
#SBATCH --error=PLASIM-large-dev-resample_%j.log 
#SBATCH --partition=batch

#source \$HOME/my_venv/bin/activate
#module load scipy

cd ${expdir}/resampling/
for a in \`ls *.tar\`; do
    tar -xvf \$a
done

# cat *.tar | tar xvf

cd ${scriptdir}/
echo '*******'
echo 'Begin reconstruct.py'
python3 -t reconstruct.py  ${expdir} ${expname} ${ntrajs} ${TotDaysBlock} 1 ${endblock}

# echo '*******'
# echo 'Begin reconstruct_var_V2.py'
# python3 -t reconstruct_var_V2.py  ${expdir} ${expname} ${ntrajs} 1 ${endblock}

echo '*******'
rm ${expdir}/resampling/*_resampling.????.npz # tar files are kept
mv ${scriptdir}/PLASIM-large-dev-resample_\${SLURM_JOB_ID}.log ${expdir}/. ## COPIA FILE LOG DENTRO CARTELLA ESPERIMENTO
mv ${scriptdir}/PLASIM-large-dev-resample_${SLURM_JOB_ID_PARENT}.sh ${scriptsexpdir}/PLASIM-large-dev-resample_\${SLURM_JOB_ID}.sh

exit 0
EOT

cd ${scriptdir}
sbatch run_PLASIM-large-dev-resample_${SLURM_JOB_ID}.sh
# ##


exit 0

