#!/bin/bash

# Function to display usage message
usage() {
    echo "Usage: $0 -i /path/to/auth.log -o /path/to/output.csv"
    exit 1
}

# Parse command-line options
while getopts ":i:o:" opt; do
    case ${opt} in
        i )
            input_file=$OPTARG
            ;;
        o )
            output_file=$OPTARG
            ;;
        \? )
            usage
            ;;
    esac
done

# Check if input and output files are provided
if [ -z "$input_file" ] || [ -z "$output_file" ]; then
    usage
fi

# Write CSV header
echo "Timestamp,Hostname,Service,ProcessID,Status,User,SourceIP,SourcePort,Message" > "$output_file"

# Convert auth.log to CSV format specifically for SSH login attempts
awk '
    /sshd/ && /Failed password/ {
        timestamp = $1" "$2" "$3;
        hostname = $4;
        service_name = "sshd";
        split($5, arr, "[");
        process_id = substr(arr[2], 1, length(arr[2])-1);
        status = "Failed";
        user = $9;
        src_ip = $11;
        src_port = $13;
        message = "Failed password for " user " from " src_ip " port " src_port;
        print "\""timestamp"\",\""hostname"\",\""service_name"\",\""process_id"\",\""status"\",\""user"\",\""src_ip"\",\""src_port"\",\""message"\"";
    }
    /sshd/ && /Accepted password/ {
        timestamp = $1" "$2" "$3;
        hostname = $4;
        service_name = "sshd";
        split($5, arr, "[");
        process_id = substr(arr[2], 1, length(arr[2])-1);
        status = "Accepted";
        user = $9;
        src_ip = $11;
        src_port = $13;
        message = "Accepted password for " user " from " src_ip " port " src_port;
        print "\""timestamp"\",\""hostname"\",\""service_name"\",\""process_id"\",\""status"\",\""user"\",\""src_ip"\",\""src_port"\",\""message"\"";
    }
' "$input_file" >> "$output_file"

echo "Conversion complete. Output saved to $output_file"
