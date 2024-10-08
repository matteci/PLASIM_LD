import sys
import os
import numpy as np
import subprocess

# read input
script=sys.argv[0]
expdir=sys.argv[1]
expname=sys.argv[2]
#fieldname=sys.argv[3]
ntrajs=int(sys.argv[3])
initblock=int(sys.argv[4])
endblock=int(sys.argv[5])

os.chdir(expdir)

print(sys.argv)

resamplingdir=expdir+'/resampling'
datadir=expdir+'/data'

# define number of blocks
nblocks=endblock-initblock+1
initblock_label=str(initblock)
endblock_label=str(endblock)

#initblock_1_label=str(1)
#endblock_45_label=str(45)
#endblock_45=45

# define label arrays. initlabel_ens containes the initlabels for each block, while initlabel_eff contains the effective genealogy of the trajectories
initlabelnow=np.arange(ntrajs)
initlabelold=np.arange(ntrajs)

# define label arrays. initlabel_ens containes the initlabels for each block, while initlabel_eff contains the effective genealogy of the trajectories
initlabelnow=np.arange(ntrajs)
initlabelold=np.arange(ntrajs)

# backward loop over the blocks. given the way python works the range looks weird, but it is correct 
os.chdir(datadir)

for block in reversed(range(initblock-1,endblock)):
#for block in reversed(range(endblock-3,endblock)):
    block_label=str(block+1)
    #print('reconstructing '+expname+', '+fieldname+', block '+block_label)
    print('reconstructing '+expname+', block '+block_label)
    sys.stdout.flush()
    # extract data from the current block
    resamplingdata=np.load(resamplingdir+'/'+expname+'_resampling.'+block_label.zfill(4)+'.npz')
    initlabel=resamplingdata['initlabel']
    # compute the labels for the reconstruction. the labels are updated keeping track of the labels of the previous (actually following) block
    initlabelnow[:]=initlabel[initlabelold]
    initlabelold[:]=initlabelnow[:]

    datatarname=expname+'_data_block_'+block_label.zfill(4)+'.tar'
    subprocess.call('tar -xvf '+datatarname, shell=True)

    for traj in range(ntrajs):
        traj_label=str(traj+1)
        clone_label=str(initlabelnow[traj]+1)
        print('block '+block_label+' traj '+traj_label+' clone '+clone_label)

        filein=expname+'_data.'+clone_label.zfill(4)+'.'+block_label.zfill(4)+'.nc'
        fileout=expname+'.'+'data'+'.'+traj_label.zfill(4)+'_'+block_label.zfill(4)+'.'+initblock_label.zfill(4)+'_'+endblock_label.zfill(4)+'.nc'

        if block==(endblock-1):
            subprocess.call('cdo -L setyear,1 '+filein+' '+fileout, shell=True)
        else:
            subprocess.call('cdo -L setyear,1 '+filein+' '+fileout, shell=True)
    subprocess.call('rm '+expname+'_data.'+'????'+'.'+block_label.zfill(4)+'.nc', shell=True)        
    subprocess.call('rm '+expname+'_ocean.'+'????'+'.'+block_label.zfill(4)+'.nc', shell=True)        
    subprocess.call('rm '+expname+'_ice.'+'????'+'.'+block_label.zfill(4)+'.nc', shell=True)        

for traj in range(ntrajs):
    traj_label=str(traj+1)
    filein=expname+'.'+'data'+'.'+traj_label.zfill(4)+'_*.'+initblock_label.zfill(4)+'_'+endblock_label.zfill(4)+'.nc'
    fileout=expname+'.'+'data'+'.'+traj_label.zfill(4)+'.'+initblock_label.zfill(4)+'_'+endblock_label.zfill(4)+'.nc'
    subprocess.call('cdo -f nc mergetime '+filein+' '+fileout, shell=True)
    subprocess.call('rm '+filein, shell=True)

if initblock==1:
    datatarname=expname+'.'+'data'+'.eff.'+initblock_label.zfill(4)+'_'+endblock_label.zfill(4)+'.tar'
    filein=expname+'.'+'data'+'.'+'*'+'.'+initblock_label.zfill(4)+'_'+endblock_label.zfill(4)+'.nc'
    subprocess.call('tar cvf '+datatarname+' '+filein, shell=True)
    subprocess.call('rm '+filein, shell=True)

exit()

