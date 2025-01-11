![ONT_gil](https://github.com/user-attachments/assets/40207d42-d75c-43ce-b34b-292de3edacbe)

```markdown
# Live Basecalling Script for Guppy on fast5 Files
(Adaptable for pod5 files under dorado basecaller)

This repository contains a Bash script designed for real-time monitoring and basecalling of Nanopore `.fast5` files using Guppy. The script leverages `inotifywait` to observe a specified directory for new `.fast5` files, processes them using Guppy for super-accuracy basecalling, and saves the resulting `.fastq` files to a designated output directory.

## Features
- **Real-Time Monitoring:** Monitors a directory for new `.fast5` files.
- **Flexible Basecalling:** Automatically performs basecalling using Guppy with configurable flowcell, kit, and model parameters.
- **CUDA Support:** Utilizes GPU acceleration for faster basecalling.
- **Batch Organization:** Processes files in batches and organizes output files into a single location.
- **User-Friendly Interface:** Accepts command-line arguments for easy customization, including a `-h` option to display help.


## Requirements
1. **Guppy Basecaller**: Ensure Guppy is installed and accessible on your system.
2. **inotify-tools**: Required for monitoring file system events. Install with:


```bash
   sudo apt-get install inotify-tools
```

**CUDA**: GPU-based basecalling requires an NVIDIA GPU with CUDA drivers installed.


## Usage
### Display Help
To see all available options and their descriptions, run the script with the `-h` or `--help` flag:

```bash
./live_basecalling.sh -h
```

### Running the Script
```bash
./live_basecalling.sh --observe-dir PATH --save-dir PATH --guppy-basecaller PATH [OPTIONS]
```

### Mandatory Arguments
- `--observe-dir PATH`: Directory to observe for `.fast5` files.
- `--save-dir PATH`: Directory to save output `.fastq` files.
- `--guppy-basecaller PATH`: Path to the Guppy basecaller executable.

### Optional Arguments
- `--flowcell STRING`: Flowcell type (default: `FLO-MIN114`).
- `--kit STRING`: Kit type (default: `SQK-RBK114-24`).
- `--model STRING`: Basecalling model (default: `dna_r10.4.1_e8.2_sup.cfg`).
- `--cuda STRING`: CUDA device (default: `cuda:0`).
- `-h, --help`: Display this help message.

## Example Command
```bash
./live_basecalling.sh \
    --observe-dir /path/to/input \
    --save-dir /path/to/output \
    --guppy-basecaller /path/to/guppy_basecaller \
    --flowcell FLO-MIN114 \
    --kit SQK-RBK114-24 \
    --model dna_r10.4.1_e8.2_sup.cfg \
    --cuda cuda:0
```

### Expected Output
The script will:
1. Monitor the input directory for `.fast5` files.
2. Basecall new `.fast5` files using Guppy.
3. Save high-quality `.fastq` files to `/path/to/output/pass_fastq`

## Notes
- Ensure the paths provided in the arguments exist and are accessible.
- If using GPU acceleration, confirm the availability of compatible CUDA drivers.


## Troubleshooting
### Common Errors
1. **`command not found: inotifywait`**
   - Install `inotify-tools` using:
     ```bash
     sudo apt-get install inotify-tools
     ```

2. **Incorrect Guppy Path**
   - Verify that the `--guppy-basecaller` path points to the Guppy executable.

3. **CUDA Issues**
   - Ensure your system has NVIDIA GPU drivers and CUDA installed. Test with:
     ```bash
     nvidia-smi
     ```
