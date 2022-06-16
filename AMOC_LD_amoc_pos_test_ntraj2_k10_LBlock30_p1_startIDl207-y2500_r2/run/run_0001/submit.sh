#!/bin/sh
#SBATCH --out=job.out
#SBATCH --time=00:30:00
#SBATCH --nodes=1 --ntasks-per-node=1 --cpus-per-task=1
#SBATCH --partition=debug

./most_plasim_t21_l10_p1.x

exit 0


