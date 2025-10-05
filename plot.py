import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

df = pd.read_csv("./data/energy_monitor_123.csv", usecols=["Time", "Energy", "Active_Power"])

df["Time"] = pd.to_datetime(df["Time"], format="%Y-%m-%d %H:%M:%S")
df["Elapsed"] = df["Time"].sub(df["Time"].iloc[0])
df["Elapsed"] = df["Elapsed"].dt.seconds

df["Accumulated"] = df["Energy"].diff()

data = df.to_numpy()
energy_acumulated = data[:,4]
time = data[:,3]
active_power = data[:,2]
energy = data[:,1]

plt.figure(figsize=(12, 4))
plt.plot(time, active_power, 'm-')
plt.title('Instant Power Consumption')
plt.xlabel('Time (s)')
plt.ylabel('Active Power (W)')
plt.ylim(300,750)
plt.xlim(0,4450)

plt.grid(True)
plt.savefig('stress_poti_1_nodes_output.png', dpi=300)
