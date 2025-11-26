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

OUT_FILE="${KEY}/${KEY}_output.csv"
echo "time,cpu,io,memory,nodes,exp,order,start_ts,end_ts" > "$OUT_FILE"

sleep 30
# Skip header and read the rest
tail -n +2 "$CSV_FILE" | while IFS=',' read -r time cpu io memory nodes exp order; do
    STRESS_PARAMETERS=""
    ((cpu > 0)) && STRESS_PARAMETERS+=" --cpu $cpu"
    ((io > 0)) && STRESS_PARAMETERS+=" --io $io"
    ((memory > 0)) && STRESS_PARAMETERS+=" --vm $memory"
    STRESS_PARAMETERS+=" --timeout $time"

    start_ts=$(date '+%F %T')

    for machine in $(head -n "$nodes" "$HOSTFILE" | cut -d" " -f1); do
        ssh -n "$machine" "$(which stress) $STRESS_PARAMETERS" &
    done

    sleep $time

    end_ts=$(date '+%F %T')
    echo "$time,$cpu,$io,$memory,$nodes,$exp,$order,$start_ts,$end_ts" >> "$OUT_FILE"
    sleep 30
done

echo "End of executions"
