#!/bin/bash
#SBATCH --time=08:00:00
#SBATCH --output=./%x_%J/%J.out
#SBATCH --error=./%x_%J/%J.err

# fail on error
# https://gist.github.com/mohanpedala/1e2ff5661761d3abd0385e8223e16425
set -euxo pipefail

KEY=${SLURM_JOB_NAME}_${SLURM_JOB_ID}

# GUIX (https://guix.gnu.org/cookbook/en/html_node/Setting-Up-Compute-Nodes.html)
GUIX_DAEMON_SOCKET="guix://192.168.30.23"
export GUIX_DAEMON_SOCKET
GUIX_LOCPATH=/var/guix/profiles/per-user/root/guix-profile/lib/locale
export GUIX_LOCPATH
for GUIX_PROFILE in "$HOME/.config/guix/current"
do
  if [ -f "$GUIX_PROFILE/etc/profile" ]; then
    . "$GUIX_PROFILE/etc/profile"
  fi
done
#GUIX end

#hostname

# Install requirements (usually done before)
GUIX_MANIFEST="${KEY}/${KEY}_chameleon.scm"

cat <<EOF > $GUIX_MANIFEST
	(use-modules (guix transformations)
		     (inria storm)
		     (ufrgs ufrgs)
		     (guix-hpc packages solverstack)
		     (gnu packages pretty-print)
		     (guix packages))

	(packages->manifest
	  (list (specification->package "chameleon@1.3.0")
		(specification->package "starpu@1.4.9")
		(specification->package "openmpi@4")
		(specification->package "gcc-toolchain@14")))
EOF

set +u
eval "$(guix shell -m ${GUIX_MANIFEST} --search-paths)"
set -u

# Create the hostfile
HOSTFILE="${KEY}/${SLURM_JOB_ID}.nodes"
srun -l hostname | sort -n | awk '{print $2}' > $HOSTFILE

# Read experiments and execute
CSV_FILE="${SLURM_JOB_NAME}_experimental_project.csv"

rsync ${CSV_FILE} ./${KEY}/
rsync $0 ./${KEY}/${KEY}.slurm

# Control experimental parameters
for machine in $(cat $HOSTFILE | cut -d" " -f1); do
    #ssh $machine 'echo 0 | tee /sys/devices/system/cpu/cpufreq/boost'
    ssh $machine 'for i in $(seq 0 $(( $(nproc) - 1 ))); do maxf=$(cat /sys/devices/system/cpu/cpu$i/cpufreq/cpuinfo_max_freq); cpufreq-set -c $i -g performance -d $maxf -u $maxf; done'
done

OPENMPI_PARAMETERS=""
# This is necessary to avoid sbatch + mpirun problems
OPENMPI_PARAMETERS="--mca plm rsh --mca oob_tcp_if_include enp4s0 --mca btl_tcp_if_include enp4s0 --bind-to none"
export OMPI_MCA_plm=isolated
srun -l hostname | sort -n | awk '{print $2}' | sed 's/$/ slots=1/' > $HOSTFILE

OUT_FILE="${KEY}/${KEY}_output.csv"
echo "size,block_size,scheduler,pq,gpu,nodes,exp,order,start_ts,end_ts" > "$OUT_FILE"

OUTPUT_DIR="${KEY}/output/"
mkdir -p $OUTPUT_DIR

# Skip header and read the rest
tail -n +2 "$CSV_FILE" | while IFS=',' read -r size block_size scheduler pq gpu nodes exp order; do
    p=$(echo "$pq" | cut -d'x' -f1)

    export STARPU_NCUDA=$gpu

    export STARPU_SCHED=$scheduler
    export STARPU_WORKERS_CPUID="0 1 2 3 4 5 6 7"

    STARPU_ENV_VARS=""
    STARPU_ENV_VARS+=" -x STARPU_NCUDA"
    STARPU_ENV_VARS+=" -x STARPU_SCHED"
    STARPU_ENV_VARS+=" -x STARPU_WORKERS_CPUID"

    start_ts=$(date '+%F %T')

    $(which mpirun) \
    -n $nodes \
    ${STARPU_ENV_VARS} \
    $OPENMPI_PARAMETERS \
    -machinefile $HOSTFILE \
    $(which chameleon_dtesting) \
    -o dgetrf_nopiv \
    -m $size \
    -n $size \
    -b $block_size \
    -w  \
    -P $p > ${OUTPUT_DIR}/$order.out < /dev/null

    end_ts=$(date '+%F %T')
    echo "$size,$block_size,$scheduler,$pq,$gpu,$nodes,$exp,$order,$start_ts,$end_ts" >> "$OUT_FILE"

done

echo "End of executions"
