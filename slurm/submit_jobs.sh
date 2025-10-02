#!/bin/bash

# lista de partições
partitions=("poti")

# loop sobre cada partição
for partition in "${partitions[@]}"; do
    sbatch --nodes=$1 --partition=$partition --job-name="stress_${partition}" stress.slurm
    sbatch --nodes=$1 --partition=$partition --job-name="lu_factor_${partition}" lu_factor.slurm 0 openmpi
done

