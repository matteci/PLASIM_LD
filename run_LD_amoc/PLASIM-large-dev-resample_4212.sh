#!/bin/sh

#SBATCH -J PLASIM-large-dev-resample_%j
#SBATCH --time=00:10:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --output=PLASIM-large-dev-resample_%j.log
#SBATCH --error=PLASIM-large-dev-resample_%j.log 
#SBATCH --partition=batch

source $HOME/my_venv/bin/activate
#module load scipy
v
cd /work/users/zappa/PLASIM/PLASIM-master/AMOC_LD_amoc_pos_test_ntraj2_k10_LBlock1_p1_startIDl207-y2500_r2/resampling/
for a in `ls *.tar`; do
    tar -xvf $a
done

#cat *.tar | tar xvf

cd /home/cini/work/PLASIM-LD/run_LD_amoc/
echo '*******'
echo 'Begin reconstruct.py'
python -t reconstruct.py  /work/users/zappa/PLASIM/PLASIM-master/AMOC_LD_amoc_pos_test_ntraj2_k10_LBlock1_p1_startIDl207-y2500_r2 AMOC_LD_amoc_pos_test_ntraj2_k10_LBlock1_p1_startIDl207-y2500_r2 2 1 1 2

#echo '*******'
#echo 'Begin reconstruct_var_V2.py'
#python -t reconstruct_var_V2.py  /work/users/zappa/PLASIM/PLASIM-master/AMOC_LD_amoc_pos_test_ntraj2_k10_LBlock1_p1_startIDl207-y2500_r2 AMOC_LD_amoc_pos_test_ntraj2_k10_LBlock1_p1_startIDl207-y2500_r2 2 1 2

echo '*******'
rm /work/users/zappa/PLASIM/PLASIM-master/AMOC_LD_amoc_pos_test_ntraj2_k10_LBlock1_p1_startIDl207-y2500_r2/resampling/*_resampling.????.npz # tar files are kept
mv /home/cini/work/PLASIM-LD/run_LD_amoc/PLASIM-large-dev-resample_${SLURM_JOB_ID}.log /work/users/zappa/PLASIM/PLASIM-master/AMOC_LD_amoc_pos_test_ntraj2_k10_LBlock1_p1_startIDl207-y2500_r2/. ## COPIA FILE LOG DENTRO CARTELLA ESPERIMENTO
mv /home/cini/work/PLASIM-LD/run_LD_amoc/PLASIM-large-dev-resample_4212.sh /work/users/zappa/PLASIM/PLASIM-master/AMOC_LD_amoc_pos_test_ntraj2_k10_LBlock1_p1_startIDl207-y2500_r2/scripts/PLASIM-large-dev-resample_${SLURM_JOB_ID}.sh

exit 0
