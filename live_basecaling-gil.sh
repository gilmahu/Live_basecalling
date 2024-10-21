#!/bin/bash

batch=1

echo ""
read -p "Paste the path you want to observe: " observedir
echo ""

echo ""
read -p "Paste the path where you want to save fastq files: " save_dir
echo ""

mkdir -p "$save_dir/pass_fastq"

inotifywait -m "$observedir" -e create -e moved_to |
while read -r dir action file; do
    echo "Directory: '$dir', File: '$file', Action: '$action'"

    if [[ "$file" == *.fast5 ]]; then
        tmp_dir="$save_dir/tmp${batch}"

        mkdir -p "$tmp_dir"

        cp "$observedir/$file" "$tmp_dir"

        /home/henrik/my_scripts/ont-guppy/bin/guppy_basecaller \
        -i "$tmp_dir" \
        -s "$save_dir/basecalled_fastq${batch}" \
        --flowcell FLO-MIN114 \
        --kit SQK-RBK114-24 \
        --compress_fastq \
        -x cuda:0 \
        --model dna_r10.4.1_e8.2_sup.cfg  # Super accuracy basecalling

        rm -r "$tmp_dir"

        mv "$save_dir/basecalled_fastq${batch}/pass/"*.fastq "$save_dir/pass_fastq/"

        batch=$((batch + 1))
    else
        echo "Skipped non-fast5 file: '$file'"
    fi
done
