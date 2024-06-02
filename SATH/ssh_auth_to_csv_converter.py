import csv
import re
import argparse

def parse_auth_log(input_file, output_file):
    with open(input_file, 'r') as infile, open(output_file, 'w', newline='') as outfile:
        writer = csv.writer(outfile)
        writer.writerow(["Timestamp", "Hostname", "Service", "ProcessID", "Status", "User", "SourceIP", "SourcePort", "Message"])

        for line in infile:
            match_failed = re.match(r'(\S+\s+\d+\s+\S+)\s+(\S+)\s+sshd\[(\d+)\]:\s+Failed\s+password\s+for\s+(invalid\s+user\s+|)(\S+)\s+from\s+(\S+)\s+port\s+(\d+)', line)
            match_accepted = re.match(r'(\S+\s+\d+\s+\S+)\s+(\S+)\s+sshd\[(\d+)\]:\s+Accepted\s+password\s+for\s+(\S+)\s+from\s+(\S+)\s+port\s+(\d+)', line)
            
            if match_failed:
                timestamp, hostname, process_id, _, user, src_ip, src_port = match_failed.groups()
                status = "Failed"
                message = f"Failed password for {user} from {src_ip} port {src_port}"
                writer.writerow([timestamp, hostname, "sshd", process_id, status, user, src_ip, src_port, message])
            elif match_accepted:
                timestamp, hostname, process_id, user, src_ip, src_port = match_accepted.groups()
                status = "Accepted"
                message = f"Accepted password for {user} from {src_ip} port {src_port}"
                writer.writerow([timestamp, hostname, "sshd", process_id, status, user, src_ip, src_port, message])

def main():
    parser = argparse.ArgumentParser(description='Convert auth.log to CSV format for SSH login attempts.')
    parser.add_argument('-i', '--input', required=True, help='Path to the input auth.log file')
    parser.add_argument('-o', '--output', required=True, help='Path to the output CSV file')
    args = parser.parse_args()

    parse_auth_log(args.input, args.output)
    print(f"Conversion complete. Output saved to {args.output}")

if __name__ == '__main__':
    main()
