# CMP223 - Energy measurements in HPC Architectures

This project is developed as part of a university course and focuses on performing energy measurements in High-Performance Computing (HPC) architectures, specifically the the poti machines at the INF-UFRGS PCAD. The main objective is to enable energy monitoring to optimize energy performance and allow power management initiatives.

## Experiments Outline

- Idle measurements
- CPU measurements
	- Application: LU factorization
	- Stress 
- GPU measurements (stage 3 maybe?)
	- Application?
	- Stress?

We selected the machines in the poti partition as computational object, since all the machines have the same technical specification. We might do additional measurements using the tupi partition. 

| Partition | CPU | RAM | Accelerator | Disk | Motherboard |
| --------- | --- | --- | ----------- | ---- | ----------- |
|poti[1,2,3,4,5] | Intel(R) Core(TM) i7-14700KF, 3.40 GHz, 28 threads, 20 cores | 96 GB DDR5 | NVIDIA GeForce RTX 4070 | 1.7 TB SSD, 119.2 GB NVME | Gigabyte Technology Co., Ltd. Z790 UD AX |
|tupi[5,6]| Intel(R) Core(TM) i9-14900KF, 3.20 GHz, 32 threads, 24 cores | 128 GB DDR5 | NVIDIA GeForce RTX 4090 | 1.7 TB SSD, 1.8 TB NVME | Gigabyte Technology Co., Ltd. Z790 UD AX |
|tupi[3,4] | Intel(R) Core(TM) i9-14900KF, 3.20 GHz, 32 threads, 24 cores | 128 GB DDR5 | NVIDIA GeForce RTX 4090 | 1.8 TB NVME | Gigabyte Technology Co., Ltd. Z790 UD AX |
|tupi2 | Intel(R) Xeon(R) E5-2620 v4, 2.10 GHz, 16 threads, 8 cores | 224 GB DDR4 | NVIDIA GeForce RTX 4090 | 3.6 TB HDD, 894.3 GB SSD, 223.6 GB SSD | ASUSTeK COMPUTER INC. X99-DELUXE II |
|tupi1 | Intel(R) Xeon(R) E5-2620 v4, 2.10 GHz, 16 threads, 8 cores | 256 GB DDR4 | NVIDIA GeForce RTX 4090 | 447.1 GB SSD, 1.8 TB SSD | ASUSTeK COMPUTER INC. X99-A II |

## CPU measurements (stage 2)

Response variable (outcome of the experiment):
- Energy consumption (kWh)

Factors and levels (parameters affecting the response and their values):
- Machines in use: 1, 2, 3, 4, 5
- CPU workload: LU factorization matrix size????? 3 levels?

Replication: 3 times?? 5 times??

Experimental design:
- Run each level of CPU workload for each level of machines in use once, see if we can capture the energy consumption of the small workloads
- Cross out some factor-level combinations
- Run the experiment a few times, see if we have significant variation in the measurements, decide the replication number
- Run the experiment with the desired replication

## Energy measurement script

The measurements are made using SNMP requests directly to the Power Distribution Units (PDUs) supplying energy to the machines. In order to query the SNMP data, the .MIB file supplied by the vendor of the PDU must be available for the SNMP agent in your /home/username/.snmp/mibs directory in the gppd-hpc machine (front). Some additional .mib files are supplied to correct SNMP errors in the output. The files are in the `mibs` directory. You can use scp to place them in the right folder (you'll only have to run this once, before using the script for the first time):

```
scp mibs/*.mib username@gppd-hpc.inf.ufrgs.br:/home/users/username/.snmp/mibs
```

The PDU's network interface is reachable from inside the cluster's private network. Each of the PDUs monitored in this experiment currently supports one whole partition. The PDU number corresponds to the last three digits of each IP address inside the private network.

| Partition         | PDU |
| ----------------- | --- |
| tupi[1,2,3,4,5,6] | 122 |
| poti[1,2,3,4,5]   | 123 |

The bash script making the SNMP requests runs in the gppd-hpc machine (front), in order to access the PDUs in the cluster's private network. It requires the number of the desired PDU, and outputs the date in YYYY-MM-DD hh:mm:ss, the cumulative energy in Wh, and the active power in W. The following command runs the script in background and redirects the output to a file: 

```
./snmp_energy_monitor.sh <PDU_number> >> energy_monitor_<PDU_number>.csv &
```

To fetch the measurement data from the front, you can use scp in your local machine:

```
scp username@gppd-hpc.inf.ufrgs.br:/home/users/username/energy_monitor_<PDU_number>.csv /home/username/
```

