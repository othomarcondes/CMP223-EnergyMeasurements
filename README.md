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

We selected the machines in the poti partition as computational object, since all the machines have the same technical specification: 
- CPU: Intel(R) Core(TM) i7-14700KF, 3.40 GHz, 28 threads, 20 cores
- RAM: 96 GB DDR5
- GPU: NVIDIA GeForce RTX 4070
- Disk: 1.7 TB SSD, 119.2 GB NVME
- Motherboard: Gigabyte Technology Co., Ltd. Z790 UD AX

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
