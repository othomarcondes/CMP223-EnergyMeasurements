#!/bin/bash
#SBATCH --time=1-00:00:00
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
GUIX_MANIFEST="${KEY}/${KEY}.scm"

cat <<EOF > $GUIX_MANIFEST
	(use-modules (guix transformations)
		     (guix packages))

	(packages->manifest
	  (list (specification->package "stress")))
EOF

set +u
eval "$(guix shell -m ${GUIX_MANIFEST} --search-paths)"
set -u

# Create the hostfile
HOSTFILE="${KEY}/${SLURM_JOB_ID}.nodes"
srun -n 1 -l hostname | sort -n | awk '{print $2}' > $HOSTFILE

# Read experiments and execute
CSV_FILE="${SLURM_JOB_NAME}_experimental_project.csv"
OUTPUT_DIR=${KEY}/output_${KEY}
mkdir -p ${OUTPUT_DIR}

rsync ${CSV_FILE} ./${KEY}/

# Control experimental parameters
for machine in $(cat $HOSTFILE | cut -d" " -f1); do
    ssh $machine 'echo 0 | tee /sys/devices/system/cpu/cpufreq/boost'
    ssh $machine 'for i in $(seq 0 $(( $(nproc) - 1 ))); do maxf=$(cat /sys/devices/system/cpu/cpu$i/cpufreq/cpuinfo_max_freq); cpufreq-set -c $i -g performance -d $maxf -u $maxf; done'
    # TODO: disable HT cores
#    ssh $machine 'for i in $(seq 24 47); do echo 0 > /sys/devices/system/cpu/cpu${i}/online; done'
done

OUT_FILE="$S{SLURM_JOB_NAME}_output.csv"
echo "time,cpu,io,memory,nodes,exp,order,start_ts,end_ts" > "$OUT_FILE"

# Skip header and read the rest
tail -n +2 "$CSV_FILE" | while IFS=',' read -r time cpu io memory nodes exp order; do

    start_ts=$(date '+%F %T')
    for machine in $(head -n "$nodes" "$HOSTFILE" | cut -d" " -f1); do

        ssh "$machine" "$(which stress) --cpu $cpu --io $io --vm $memory --timeout $time"

    done
    end_ts=$(date '+%F %T')
    echo "$time,$cpu,$io,$memory,$nodes,$exp,$order,$start_ts,$end_ts" >> "$OUT_FILE"

done

echo "End of executions"
