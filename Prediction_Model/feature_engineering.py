from clean_logs import process_logs  # Import the function from clean_logs.py
import pandas as pd

def feature_engineering(df):
    keywords = ['error', 'failure', 'critical', 'warning']  # Keywords to look for in logs

    # Count the number of occurrences of each keyword
    for keyword in keywords:
        df[keyword + '_count'] = df['message'].apply(lambda x: x.count(keyword))

    # Add additional features
    df['message_length'] = df['message'].apply(len)
    df['unique_message_count'] = df.groupby('host')['message'].transform('nunique')

    return df

# Load the cleaned logs data (this can be adjusted if the location of logs changes)
log_file = '/mnt/nfs_project/logs/system_logs.json'

# Clean the logs (you can replace the process_logs function if it does additional cleaning)
df = process_logs(log_file)

# Perform feature engineering on the cleaned logs
df = feature_engineering(df)

# Print the first few rows of the feature-engineered DataFrame
print(df.head())
