#!/bin/bash

# lista de partições
partitions=("cei")

# loop sobre cada partição
for partition in "${partitions[@]}"; do
    sbatch --nodes=$1 --partition=$partition --job-name="$partition" partitions.slurm 1 openmpi
done

