![ONT_gil](https://github.com/user-attachments/assets/40207d42-d75c-43ce-b34b-292de3edacbe)


````markdown
# Live Basecalling Script for Guppy (FAST5) and Dorado (POD5)

This repository contains a Bash script designed for real-time monitoring and basecalling of Nanopore data. It leverages `inotifywait` to observe a specified directory for new files and automatically basecalls them using the appropriate engine:

- `.fast5` files → **Guppy**
- `.pod5` files → **Dorado**

## Features
- Real-Time Monitoring: Watches a directory for new `.fast5` or `.pod5` files.
- Flexible Basecalling: Routes files to Guppy or Dorado, or force an engine with `--engine`.
- Configurable Parameters: Flowcell, kit, and model for Guppy; model for Dorado.
- CUDA Support: GPU acceleration for faster basecalling.
- Batch Organization: Processes files in batches and organizes output files into a single location.
- User-Friendly Interface: Accepts command-line arguments for easy customization, including a `-h` option to display help.

## Requirements
1. **inotify-tools**: Required for monitoring file system events.  
   Install with:
   ```bash
   sudo apt-get install inotify-tools
````

2. **Guppy Basecaller** (required for `.fast5` workflows).
3. **Dorado Basecaller** (required for `.pod5` workflows).
4. **CUDA**: GPU-based basecalling requires an NVIDIA GPU with CUDA drivers installed.
   Test with:

   ```bash
   nvidia-smi
   ```

## Usage

### Display Help

```bash
./live_basecaling-gil.sh -h
```

### Running the Script

```bash
./live_basecaling-gil.sh --observe-dir PATH --save-dir PATH [--guppy-basecaller PATH] [--dorado PATH] [OPTIONS]
```

### Mandatory Arguments

* `--observe-dir PATH` : Directory to observe for new files.
* `--save-dir PATH` : Directory to save output `.fastq` files.

At least one engine must be available:

* `--guppy-basecaller PATH` : Path to the Guppy basecaller executable.
* `--dorado PATH` : Path to the Dorado binary.

### Engine Selection

* `--engine {auto|guppy|dorado}` : Select engine (default: `auto`).

  * `auto` → Routes by file type (`.fast5` → Guppy, `.pod5` → Dorado).
  * `guppy` → Forces Guppy (expects `.fast5` files).
  * `dorado` → Forces Dorado (expects `.pod5` files).

### Optional Arguments (Guppy)

* `--flowcell STRING` : Flowcell type (default: `FLO-MIN114`).
* `--kit STRING` : Kit type (default: `SQK-RBK114-24`).
* `--model STRING` : Basecalling model (default: `dna_r10.4.1_e8.2_sup.cfg`).

### Optional Arguments (Dorado)

* `--dorado-model STRING` : Basecalling model (default: `dna_r10.4.1_e8.2_400bps_sup@v4.2.0`).

### Common Options

* `--cuda STRING` : CUDA device (default: `cuda:0`).
  Examples: `cuda:0`, `cuda:all`.
* `-h, --help` : Display help message.

## Example Commands

### Guppy on FAST5

```bash
./live_basecaling-gil.sh \
    --observe-dir /data/in_fast5 \
    --save-dir /data/out \
    --guppy-basecaller /opt/ont/guppy/bin/guppy_basecaller \
    --flowcell FLO-MIN114 \
    --kit SQK-RBK114-24 \
    --model dna_r10.4.1_e8.2_sup.cfg \
    --cuda cuda:0 \
    --engine guppy
```

### Dorado on POD5

```bash
./live_basecaling-gil.sh \
    --observe-dir /data/in_pod5 \
    --save-dir /data/out \
    --dorado /opt/ont/dorado/bin/dorado \
    --dorado-model dna_r10.4.1_e8.2_400bps_sup@v4.2.0 \
    --cuda cuda:all \
    --engine dorado
```

### Auto-route Both

```bash
./live_basecaling-gil.sh \
    --observe-dir /data/in \
    --save-dir /data/out \
    --guppy-basecaller /opt/ont/guppy/bin/guppy_basecaller \
    --dorado /opt/ont/dorado/bin/dorado \
    --cuda cuda:all \
    --engine auto
```

## Expected Output

1. The script monitors the input directory for `.fast5` and `.pod5` files.
2. New files are basecalled with the appropriate engine.
3. FASTQ files are saved under:

   ```
   /path/to/output/pass_fastq
   ```

## Notes

* Ensure provided paths exist and are accessible.
* If using GPU acceleration, confirm the availability of compatible CUDA drivers with `nvidia-smi`.

## Troubleshooting

### `command not found: inotifywait`

Install inotify-tools:

```bash
sudo apt-get install inotify-tools
```

### Incorrect Guppy Path

Verify the `--guppy-basecaller` path points to the Guppy executable:

```bash
which guppy_basecaller
```

### Incorrect Dorado Path

Verify the `--dorado` path points to the Dorado executable:

```bash
which dorado
```

### CUDA Issues

Ensure your system has NVIDIA GPU drivers and CUDA installed:

```bash
nvidia-smi
```

```
