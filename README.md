![ONT_gil](https://github.com/user-attachments/assets/40207d42-d75c-43ce-b34b-292de3edacbe)

# Live Basecalling Script for Guppy on fast5 files (Adaptable for pod5 files under dorado basecaller)

This repository contains a Bash script designed for real-time monitoring and basecalling of Nanopore `.fast5` files using Guppy. The script leverages `inotifywait` to observe a specified directory for new `.fast5` files, processes them using Guppy for super accuracy basecalling, and saves the resulting `.fastq` files to a designated output directory.

## Features
- Monitors a directory in real-time for new `.fast5` files.
- Automatically performs basecalling using Guppy with the R10.4.1 flowcell and SQK-RBK114-24 kit.
- Supports super accuracy basecalling mode (`dna_r10.4.1_e8.2_sup.cfg`).
- Organizes and batches basecalled `.fastq` files.
- Efficient handling of temporary files during basecalling.
- Supports GPU acceleration using `cuda:0`.

## Requirements
- Guppy Basecaller: Ensure that Guppy is installed and accessible at the specified path in the script.
- inotify-tools: The script uses `inotifywait` to detect file events.
- CUDA: GPU-based basecalling requires a system with a compatible NVIDIA GPU and CUDA drivers.

## Usage

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/Live_basecalling.git
   ```

2. Navigate to the script directory:
   ```bash
   cd Live_basecalling
   ```

3. Run the script:
   ```bash
   ./live_basecalling.sh
   ```

4. When prompted, enter the directory to be monitored for `.fast5` files and the directory where the resulting `.fastq` files should be saved.

## Example Command
```bash
Paste the path you want to observe: /path/to/fast5_directory
Paste the path where you want to save fastq files: /path/to/save_fastq
```

## Notes
- Make sure to modify the paths in the script to point to the correct locations of Guppy and your input/output directories.
- Ensure that `inotifywait` is installed on your system. On Ubuntu, you can install it with:
  ```bash
  sudo apt-get install inotify-tools
  ```

## License
This project is open-source and available under the [MIT License](LICENSE).
```
