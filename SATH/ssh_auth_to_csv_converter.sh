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

# Convert auth.log to CSV format specifically for SSH login attempts
awk '
    /sshd/ && /Failed password/ {
        timestamp = $1" "$2" "$3;
        hostname = $4;
        service_name = "sshd";
        split($0, a, " ");
        process_id = a[5];
        status = "Failed";
        user = a[11];
        src_ip = a[13];
        src_port = a[15];
        message = "Failed password for " user " from " src_ip " port " src_port;
        print "\""timestamp"\",\""hostname"\",\""service_name"\",\""process_id"\",\""status"\",\""user"\",\""src_ip"\",\""src_port"\",\""message"\"";
    }
    /sshd/ && /Accepted password/ {
        timestamp = $1" "$2" "$3;
        hostname = $4;
        service_name = "sshd";
        split($0, a, " ");
        process_id = a[5];
        status = "Accepted";
        user = a[9];
        src_ip = a[11];
        src_port = a[13];
        message = "Accepted password for " user " from " src_ip " port " src_port;
        print "\""timestamp"\",\""hostname"\",\""service_name"\",\""process_id"\",\""status"\",\""user"\",\""src_ip"\",\""src_port"\",\""message"\"";
    }
' "$input_file" > "$output_file"

echo "Conversion complete. Output saved to $output_file"
