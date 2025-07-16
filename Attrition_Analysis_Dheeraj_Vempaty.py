import pandas as pd
import sqlite3
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np

### Plot Heatmap based on EnvironmentSatisfaction, JobSatisfaction, and WorkLifeBalance

conn = sqlite3.connect(r'D:\Dheeraj Job\WD\AA BI Analyst Test Homework\WDAACaseStudy.db')
satisfaction_attrition_df = pd.read_sql_query(
    """   
select EnvironmentSatisfaction,JobSatisfaction,WorkLifeBalance,count(1) total_HC,
sum(case when attrition='Yes' then 1 else 0 end)*100/count(1) Attrition_percent from general_data gnr
left JOIN employee_survey_data emp 
on emp.EmployeeID=gnr.EmployeeID
left join manager_survey_data mgr
on gnr.EmployeeID=mgr.EmployeeID
where EnvironmentSatisfaction <>'NA'
and JobSatisfaction <>'NA' and WorkLifeBalance <> 'NA'
group by 1,2,3
order by 5 desc
    """,
    conn
)
conn.close()

# Create a pivot table: average attrition rate for each combination
pivot = satisfaction_attrition_df.pivot_table(
    index='WorkLifeBalance',
    columns=['EnvironmentSatisfaction', 'JobSatisfaction'],
    values='Attrition_percent'
)

plt.figure(figsize=(12, 8))
sns.heatmap(
    pivot,
    annot=True,
    fmt=".1f",
    cmap="YlOrRd",
    cbar_kws={'label': 'Attrition Rate (%)'}
)
plt.title("Attrition Rate by WorkLifeBalance, EnvironmentSatisfaction, and JobSatisfaction")
plt.ylabel("WorkLifeBalance")
plt.xlabel("EnvSatisfaction (col) / JobSatisfaction (row)")
plt.tight_layout()
plt.show()

##########################################

# Civil Status Analysis
conn = sqlite3.connect(r'D:\Dheeraj Job\WD\AA BI Analyst Test Homework\WDAACaseStudy.db')
civil_status_df = pd.read_sql_query(
    """
    select CivilStatus, count(1) total_HC,sum(case when attrition='Yes' then 1 else 0 end) Attrition_HC,
sum(case when attrition='Yes' then 1 else 0 end)*100/count(1) Attrition_percent
from general_data
group by CivilStatus
order by 4 desc;
    """,
    conn
)
conn.close()

# Plotting CivilStatus vs Attrition Percent
plt.figure(figsize=(8, 5))
bars = plt.bar(civil_status_df['CivilStatus'], civil_status_df['Attrition_percent'], color='skyblue')
plt.title('Attrition Rate by Civil Status')
plt.xlabel('Civil Status')
plt.ylabel('Attrition Rate (%)')
plt.ylim(0, civil_status_df['Attrition_percent'].max() + 5)
plt.grid(axis='y', linestyle='--', alpha=0.7)

# Annotate bars
for bar in bars:
    height = bar.get_height()
    plt.text(bar.get_x() + bar.get_width()/2, height + 0.5, f"{height:.2f}%", ha='center', va='bottom')

plt.tight_layout()
plt.show()


#############################

# TravelFrequency Analysis
conn = sqlite3.connect(r'D:\Dheeraj Job\WD\AA BI Analyst Test Homework\WDAACaseStudy.db')
travel_freq_df = pd.read_sql_query(
"""select TravelFrequency, count(1) total_HC,
sum(case when attrition='Yes' then 1 else 0 end)*100/count(1) Attrition_percent
from general_data
group by TravelFrequency
order by 3 desc"""
,conn)
conn.close()

# Plotting TravelFrequency vs Attrition Percent
plt.figure(figsize=(7, 7))
plt.pie(
    travel_freq_df['Attrition_percent'],
    labels=travel_freq_df['TravelFrequency'],
    autopct='%1.1f%%',
    startangle=140,
    colors=sns.color_palette('pastel')[0:len(travel_freq_df)]
)
plt.title('Attrition Rate Distribution by Travel Frequency')
plt.tight_layout()
plt.show()

### DistanceFromHome Analysis
conn = sqlite3.connect(r'D:\Dheeraj Job\WD\AA BI Analyst Test Homework\WDAACaseStudy.db')
distance_home_df = pd.read_sql_query(
    """  SELECT 
    CASE 
        WHEN DistanceFromHomeAddress < 5 THEN '<5 km'
        WHEN DistanceFromHomeAddress BETWEEN 5 AND 10 THEN '5-10 km'
        WHEN DistanceFromHomeAddress BETWEEN 11 AND 20 THEN '11-20 km'
        ELSE '>20 km'
    END AS DistanceGroup,
    COUNT(*) AS Total_Employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS Attrition_Count,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Attrition_Percent
FROM general_data
GROUP BY DistanceGroup
ORDER BY Attrition_Percent DESC;
    """,
    conn
)

conn.close()
# Plot DistanceGroup vs Total_Employees, Attrition_Count, and Attrition_Percent
fig, ax1 = plt.subplots(figsize=(10, 6))

bar_width = 0.35
x = range(len(distance_home_df['DistanceGroup']))

# Bar for Total Employees
bars1 = ax1.bar([i - bar_width/2 for i in x], distance_home_df['Total_Employees'], 
                width=bar_width, color='tab:blue', alpha=0.7, label='Total Employees')

# Bar for Attrition Count
bars2 = ax1.bar([i + bar_width/2 for i in x], distance_home_df['Attrition_Count'], 
                width=bar_width, color='tab:orange', alpha=0.7, label='Attrition Count')

ax1.set_xlabel('Distance From Home Group')
ax1.set_ylabel('Count')
ax1.set_xticks(x)
ax1.set_xticklabels(distance_home_df['DistanceGroup'])
ax1.legend(loc='upper left')

# Annotate bars
for bar in bars1:
    height = bar.get_height()
    ax1.text(bar.get_x() + bar.get_width()/2, height + 3, f"{int(height)}", ha='center', va='bottom', color='tab:blue')
for bar in bars2:
    height = bar.get_height()
    ax1.text(bar.get_x() + bar.get_width()/2, height + 3, f"{int(height)}", ha='center', va='bottom', color='tab:orange')

# Line for Attrition Percent
ax2 = ax1.twinx()
ax2.plot(x, distance_home_df['Attrition_Percent'], color='tab:red', marker='o', label='Attrition Percent (%)')
ax2.set_ylabel('Attrition Percent (%)', color='tab:red')
ax2.tick_params(axis='y', labelcolor='tab:red')

for i, val in enumerate(distance_home_df['Attrition_Percent']):
    ax2.text(i, val + 0.5, f"{val:.2f}%", color='tab:red', ha='center', va='bottom')

plt.title('Distance From Home: Total Employees, Attrition Count vs Attrition Percent')
fig.tight_layout()
plt.show()

############
# Ethnicity & Gender Analysis
conn = sqlite3.connect(r'D:\Dheeraj Job\WD\AA BI Analyst Test Homework\WDAACaseStudy.db')   
ethnicity_df= pd.read_sql_query(
    """select Ethnicity,Gender, count(1) total_HC,
sum(case when attrition='Yes' then 1 else 0 end)*100/count(1) Attrition_percent
from general_data where ethnicity is not null
group by Ethnicity,Gender;""",
    conn  )
conn.close()

# Set the style for seaborn
sns.set(style="whitegrid")          
# Create a pivot table for better visualization
ethnicity_pivot = ethnicity_df.pivot_table(
    index='Ethnicity',
    columns='Gender',
    values='Attrition_percent'
)

plt.figure(figsize=(10, 6))
sns.heatmap(
    ethnicity_pivot,
    annot=True,
    fmt=".1f",
    cmap="Blues",
    cbar_kws={'label': 'Attrition Rate (%)'}
)
plt.title("Attrition Rate by Ethnicity and Gender")
plt.xlabel("Gender")
plt.ylabel("Ethnicity")
plt.tight_layout()
plt.show()








# Connect to the SQLite database
conn = sqlite3.connect(r'D:\Dheeraj Job\WD\AA BI Analyst Test Homework\WDAACaseStudy.db')

# Load in_time and out_time data
in_time_df = pd.read_sql_query("SELECT * FROM in_time", conn)
out_time_df = pd.read_sql_query("SELECT * FROM out_time", conn)
# Load Attrition and EmployeeID from general_data
attrition_df = pd.read_sql_query("SELECT EmployeeID, Attrition FROM general_data", conn)

conn.close()
# Replace "NA" strings with actual NaT (missing datetime)
in_time_df.replace("NA", pd.NaT, inplace=True)
out_time_df.replace("NA", pd.NaT, inplace=True)

# Ensure all columns except EmployeeID are datetime
for df in [in_time_df, out_time_df]:
    for col in df.columns[1:]:
        df[col] = pd.to_datetime(df[col], errors='coerce')

print("in_time_df dtypes:\n", in_time_df.dtypes)
print("out_time_df dtypes:\n", out_time_df.dtypes)

# Calculate hours worked per day (vectorized, no .dt needed)
hours_worked = (out_time_df.iloc[:, 1:] - in_time_df.iloc[:, 1:]) / pd.Timedelta(hours=1)

# Combine with EmployeeID
hours_worked_df = pd.concat([out_time_df[['EmployeeID']], hours_worked], axis=1)

# Compute average daily hours worked per employee
hours_worked_df['AvgDailyHours'] = hours_worked.mean(axis=1)
avg_hours_df = hours_worked_df[['EmployeeID', 'AvgDailyHours']]

print(avg_hours_df.head())

# Merge average hours worked with attrition status
merged_df = pd.merge(avg_hours_df, attrition_df, on='EmployeeID')

# Create working hour bands
merged_df['HourBand'] = pd.cut(
    merged_df['AvgDailyHours'],
    bins=[0, 6, 7, 8, 9, 12],
    labels=['<6 hrs', '6–7 hrs', '7–8 hrs', '8–9 hrs', '>9 hrs']
)

# Analyze attrition rate by average daily hour band
hour_band_summary = (
    merged_df.groupby('HourBand')
    .agg(
        Total_Employees=('EmployeeID', 'count'),
        Attrition_Count=('Attrition', lambda x: (x == 'Yes').sum()),
    )
)
hour_band_summary['Attrition_Rate (%)'] = (hour_band_summary['Attrition_Count'] / hour_band_summary['Total_Employees'] * 100).round(2)

hour_band_summary.reset_index(inplace=True)
hour_band_summary.sort_values(by='Attrition_Rate (%)', ascending=False, inplace=True)
print(hour_band_summary.head())


# Create a bar chart to visualize the impact of AvgDailyHours on Attrition
plt.figure(figsize=(10, 6))
bars = plt.bar(hour_band_summary['HourBand'], hour_band_summary['Attrition_Rate (%)'], color='salmon')
plt.title("Attrition Rate by Average Daily Working Hours", fontsize=14)
plt.xlabel("Average Daily Hours Worked")
plt.ylabel("Attrition Rate (%)")
plt.ylim(0, max(hour_band_summary['Attrition_Rate (%)']) + 5)
plt.grid(axis='y', linestyle='--', alpha=0.7)

# Annotate the bars
for bar in bars:
    height = bar.get_height()
    plt.text(bar.get_x() + bar.get_width()/2, height + 1, f"{height:.2f}%", ha='center', va='bottom')

plt.tight_layout()
plt.show()

