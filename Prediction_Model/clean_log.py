import pandas as pd
import json
import re

# Helper function to clean logs
def clean_log(message):
    """
    Clean the log message by:
    - Converting to lowercase
    - Removing non-alphanumeric characters except spaces
    """
    if message is None:
        return ''
    message = message.lower()
    message = re.sub(r'[^a-z0-9\s]', '', message)  # Remove non-alphanumeric characters
    return message

# Function to process the logs
def process_logs(log_file):
    logs = []

    try:
        with open(log_file, 'r') as file:
            for line in file:
                try:
                    # Remove the timestamp and log level part (before the JSON data)
                    line = re.sub(r'^\S+\s+\S+\s+', '', line.strip())  # This removes timestamp and 'syslog'

                    # Each log line is expected to be a valid JSON object
                    log_data = json.loads(line)  # Now we should have a valid JSON object

                    # Extract relevant log fields and clean the message
                    log_entry = {
                        'host': log_data.get('host', ''),
                        'ident': log_data.get('ident', ''),
                        'message': clean_log(log_data.get('message', '')),
                        'timestamp': log_data.get('timestamp', ''),
                    }

                    # Only append logs that have a 'message' (non-empty) and 'host'
                    if log_entry['message'] and log_entry['host']:
                        logs.append(log_entry)

                except json.JSONDecodeError:
                    # Print invalid log entry if JSON is malformed
                    print(f"Skipping invalid log entry: {line.strip()}")
                    continue  # Skip invalid log entries

    except FileNotFoundError:
        # Print error if the log file is not found
        print(f"Error: The log file {log_file} does not exist.")
        return pd.DataFrame()  # Return an empty DataFrame if file is not found

    # Convert the collected log data to a DataFrame
    df = pd.DataFrame(logs)

    if df.empty:
        print("Warning: No valid logs found after processing.")

    return df

# Example of processing logs
log_file = '/mnt/nfs_project/logs/system_logs.json'  # Replace with your actual log file path
df = process_logs(log_file)

if not df.empty:
    print("Logs successfully processed:")
    print(df.head())  # Preview the cleaned data
else:
    print("No valid logs to process.")
