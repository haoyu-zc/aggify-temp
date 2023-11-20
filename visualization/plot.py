import matplotlib.pyplot as plt

# Hardcoded average times for each workload
avg_times_workload1 = [549.1, 2204.9, 5167.3, 4319.4, 524.0, 2819.8]
avg_times_workload2 = [348.0, 919.4, 3738.8, 765.4, 756.1, 1158.6]

# Calculate the ratios of avg_time for Workload 1 to Workload 2
ratios = [w1 / w2 if w2 else 0 for w1, w2 in zip(avg_times_workload1, avg_times_workload2)]

# The x locations for the groups
indices = range(len(avg_times_workload1))

# Bar width
bar_width = 0.35

# Create the plot
fig, ax1 = plt.subplots(figsize=(12, 7))

# Bar plot for the avg_times
bar1 = ax1.bar(indices, avg_times_workload1, bar_width, color='b', label='Workload 1')
bar2 = ax1.bar([i + bar_width for i in indices], avg_times_workload2, bar_width, color='g', label='Workload 2')

# Line plot for the ratios
ax2 = ax1.twinx()
line = ax2.plot(indices, ratios, 'r-o', label='Ratio (Workload 1 / Workload 2)')

# Labels and title
ax1.set_xlabel('Row Number')
ax1.set_ylabel('Average Time (ms)', color='b')
ax2.set_ylabel('Ratio', color='r')
plt.title('Average Time and Ratio Comparison between Workload 1 and Workload 2')

# Ticks
ax1.set_xticks([i + bar_width / 2 for i in indices])
ax1.set_xticklabels([str(i+1) for i in indices])

# Legend
lines, labels = ax1.get_legend_handles_labels()
lines2, labels2 = ax2.get_legend_handles_labels()
ax2.legend(lines + lines2, labels + labels2, loc='upper left')

# Show plot
plt.show()
