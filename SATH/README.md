# SATH
This script is designed to convert auth.log files into CSV format, specifically extracting details from SSH login attempts. It captures essential information such as timestamp, hostname, service name, process ID, status (failed or accepted), username, source IP, source port, and a detailed message. This conversion makes it easier to analyze authentication logs using spreadsheet software or other CSV-compatible tools.

# Features
Parse AuthLog Entries: Extract and convert SSH login attempts from auth.log files.
Detailed Logging: Capture detailed information including timestamp, hostname, service name, process ID, login status, username, source IP, and source port.
CSV Output: Output the parsed log entries into a structured CSV file for easy analysis

# Usage:
./convert_auth_to_csv.sh -i /path/to/auth.log -o /path/to/output.csv  
**OR**

python3 convert_auth_to_csv.py -i /path/to/auth.log -o /path/to/output.csv
