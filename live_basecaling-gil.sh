#!/bin/bash

# Default parameters
observedir=""
save_dir=""
batch=1
flowcell="FLO-MIN114"
kit="SQK-RBK114-24"
model="dna_r10.4.1_e8.2_sup.cfg"
cuda_device="cuda:0"
guppy_basecaller=""

# Function to display usage instructions
function print_usage {
    echo "Usage: $0 --observe-dir PATH --save-dir PATH --guppy-basecaller PATH [OPTIONS]"
    echo ""
    echo "Mandatory arguments:"
    echo "  --observe-dir PATH       Path to the directory to observe for .fast5 files"
    echo "  --save-dir PATH          Path to save output fastq files"
    echo "  --guppy-basecaller PATH  Path to the Guppy basecaller executable"
    echo ""
    echo "Optional arguments:"
    echo "  --flowcell STRING        Flowcell type (default: FLO-MIN114)"
    echo "  --kit STRING             Kit type (default: SQK-RBK114-24)"
    echo "  --model STRING           Basecalling model (default: dna_r10.4.1_e8.2_sup.cfg)"
    echo "  --cuda STRING            CUDA device (default: cuda:0)"
    echo "  -h, --help               Display this help message"
    echo ""
    echo "Example:"
    echo "  $0 --observe-dir /path/to/input --save-dir /path/to/output --guppy-basecaller /path/to/guppy_basecaller"
    echo "       --flowcell FLO-MIN114 --kit SQK-RBK114-24 --model dna_r10.4.1_e8.2_sup.cfg --cuda cuda:0"
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --observe-dir)
            observedir="$2"
            shift 2
            ;;
        --save-dir)
            save_dir="$2"
            shift 2
            ;;
        --flowcell)
            flowcell="$2"
            shift 2
            ;;
        --kit)
            kit="$2"
            shift 2
            ;;
        --model)
            model="$2"
            shift 2
            ;;
        --cuda)
            cuda_device="$2"
            shift 2
            ;;
        --guppy-basecaller)
            guppy_basecaller="$2"
            shift 2
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Validate mandatory parameters
if [[ -z "$observedir" || -z "$save_dir" || -z "$guppy_basecaller" ]]; then
    echo "Error: --observe-dir, --save-dir, and --guppy-basecaller are required parameters."
    echo ""
    print_usage
    exit 1
fi

# Ensure the save directory exists
mkdir -p "$save_dir/pass_fastq"

# Monitor the observed directory for new files
inotifywait -m "$observedir" -e create -e moved_to |
while read -r dir action file; do
    echo "$(date +"%Y-%m-%d %H:%M:%S") - Directory: '$dir', File: '$file', Action: '$action'"

    # Process only .fast5 files
    if [[ "$file" == *.fast5 ]]; then
        tmp_dir="$save_dir/tmp${batch}"

        mkdir -p "$tmp_dir"

        # Copy the .fast5 file to the temporary directory
        cp "$observedir/$file" "$tmp_dir"

        # Run Guppy basecaller
        "$guppy_basecaller" \
            -i "$tmp_dir" \
            -s "$save_dir/basecalled_fastq${batch}" \
            --flowcell "$flowcell" \
            --kit "$kit" \
            --compress_fastq \
            -x "$cuda_device" \
            --model "$model"

        # Check if Guppy completed successfully
        if [[ $? -ne 0 ]]; then
            echo "$(date +"%Y-%m-%d %H:%M:%S") - Error: Guppy basecalling failed for batch $batch. Skipping."
            rm -r "$tmp_dir"
            continue
        fi

        # Move pass files and clean up
        mv "$save_dir/basecalled_fastq${batch}/pass/"*.fastq "$save_dir/pass_fastq/"
        rm -r "$tmp_dir"

        echo "$(date +"%Y-%m-%d %H:%M:%S") - Batch $batch processed successfully."

        batch=$((batch + 1))
    else
        echo "$(date +"%Y-%m-%d %H:%M:%S") - Skipped non-fast5 file: '$file'"
    fi
done
