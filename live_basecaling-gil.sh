#!/usr/bin/env bash
set -euo pipefail

# Default parameters
observedir=""
save_dir=""
batch=1
flowcell="FLO-MIN114"
kit="SQK-RBK114-24"
model="dna_r10.4.1_e8.2_sup.cfg"
cuda_device="cuda:0"
guppy_basecaller=""

# Dorado defaults
engine="auto"  # auto|guppy|dorado
dorado_bin=""
dorado_model="dna_r10.4.1_e8.2_400bps_sup@v4.2.0"
threads=""

print_usage() {
    cat <<EOF
Usage:
  $0 --observe-dir PATH --save-dir PATH [--guppy-basecaller PATH] [--dorado PATH] [OPTIONS]

Monitors PATH for new .fast5 and/or .pod5 files and basecalls:
  - .fast5  => Guppy
  - .pod5   => Dorado

Mandatory:
  --observe-dir PATH           Directory to observe for new files
  --save-dir PATH              Directory to save output FASTQ files

At least one engine must be available:
  --guppy-basecaller PATH      Path to Guppy basecaller (required for .fast5 or engine=guppy)
  --dorado PATH                Path to Dorado binary (required for .pod5 or engine=dorado)

Optional (common):
  --engine {auto|guppy|dorado} Engine selection (default: auto)
  --cuda STRING                CUDA device (default: cuda:0)
  --threads INT                Optional generic threads placeholder

Optional (Guppy):
  --flowcell STRING            Flowcell type (default: FLO-MIN114)
  --kit STRING                 Kit type (default: SQK-RBK114-24)
  --model STRING               Guppy model cfg (default: dna_r10.4.1_e8.2_sup.cfg)

Optional (Dorado):
  --dorado-model STRING        Dorado model tag (default: dna_r10.4.1_e8.2_400bps_sup@v4.2.0)

Help:
  -h, --help                   Display this help message

Examples:
  $0 --observe-dir /in --save-dir /out --guppy-basecaller /path/guppy_basecaller \\
     --flowcell FLO-MIN114 --kit SQK-RBK114-24 --model dna_r10.4.1_e8.2_sup.cfg --cuda cuda:0

  $0 --observe-dir /in --save-dir /out --dorado /path/dorado --engine dorado --cuda cuda:all

  $0 --observe-dir /in --save-dir /out --guppy-basecaller /path/guppy_basecaller --dorado /path/dorado
EOF
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --observe-dir) observedir="${2:-}"; shift 2;;
        --save-dir) save_dir="${2:-}"; shift 2;;
        --flowcell) flowcell="${2:-}"; shift 2;;
        --kit) kit="${2:-}"; shift 2;;
        --model) model="${2:-}"; shift 2;;
        --cuda) cuda_device="${2:-}"; shift 2;;
        --guppy-basecaller) guppy_basecaller="${2:-}"; shift 2;;
        --engine) engine="${2:-}"; shift 2;;
        --dorado) dorado_bin="${2:-}"; shift 2;;
        --dorado-model) dorado_model="${2:-}"; shift 2;;
        --threads) threads="${2:-}"; shift 2;;
        -h|--help) print_usage; exit 0;;
        *) echo "Unknown option: $1"; print_usage; exit 1;;
    esac
done

# Validate mandatory parameters
if [[ -z "$observedir" || -z "$save_dir" ]]; then
    echo "Error: --observe-dir and --save-dir are required."
    echo
    print_usage
    exit 1
fi

# Validate engine availability
case "$engine" in
    auto)
        if [[ -z "$guppy_basecaller" && -z "$dorado_bin" ]]; then
            echo "Error: In --engine auto, provide at least one of --guppy-basecaller or --dorado."
            exit 1
        fi
        ;;
    guppy)
        if [[ -z "$guppy_basecaller" ]]; then
            echo "Error: --engine guppy requires --guppy-basecaller PATH."
            exit 1
        fi
        ;;
    dorado)
        if [[ -z "$dorado_bin" ]]; then
            echo "Error: --engine dorado requires --dorado PATH."
            exit 1
        fi
        ;;
    *)
        echo "Error: --engine must be one of {auto|guppy|dorado}."
        exit 1
        ;;
esac

# Preflight checks
if ! command -v inotifywait >/dev/null 2>&1; then
    echo "Error: 'inotifywait' not found. Install inotify-tools."
    exit 1
fi
if [[ "$engine" != "dorado" && -n "$guppy_basecaller" && ! -x "$guppy_basecaller" ]]; then
    echo "Error: Guppy basecaller not executable at: $guppy_basecaller"
    exit 1
fi
if [[ "$engine" != "guppy" && -n "$dorado_bin" && ! -x "$dorado_bin" ]]; then
    echo "Error: Dorado not executable at: $dorado_bin"
    exit 1
fi

# Prepare output
mkdir -p "$save_dir/pass_fastq"
shopt -s nullglob

echo "[INFO] Monitoring: $observedir"
echo "[INFO] Output FASTQ: $save_dir/pass_fastq"
echo "[INFO] Engine mode: $engine"
[[ -n "$guppy_basecaller" ]] && echo "[INFO] Guppy: $guppy_basecaller"
[[ -n "$dorado_bin" ]] && echo "[INFO] Dorado: $dorado_bin"

move_pass_fastqs() {
    local src_dir="$1"
    local dst_dir="$2"
    if compgen -G "$src_dir"/*.fastq > /dev/null; then
        mv "$src_dir"/*.fastq "$dst_dir"/
    fi
    if compgen -G "$src_dir"/*.fastq.gz > /dev/null; then
        mv "$src_dir"/*.fastq.gz "$dst_dir"/
    fi
}

inotifywait -m -e close_write -e moved_to --format '%w %f %e' "$observedir" | \
while read -r dir file event; do
    ts="$(date +"%Y-%m-%d %H:%M:%S")"
    path="$dir/$file"
    ext="${file##*.}"
    ext_lower="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"

    case "$ext_lower" in
        fast5|pod5) ;;
        *)
            echo "$ts - Skipped non-target file: '$file' (event: $event)"
            continue
            ;;
    esac

    echo "$ts - Detected '$file' (event: $event)"

    chosen_engine=""
    if [[ "$engine" == "auto" ]]; then
        if [[ "$ext_lower" == "fast5" && -n "$guppy_basecaller" ]]; then
            chosen_engine="guppy"
        elif [[ "$ext_lower" == "pod5" && -n "$dorado_bin" ]]; then
            chosen_engine="dorado"
        else
            need=$([[ "$ext_lower" == "fast5" ]] && echo "Guppy" || echo "Dorado")
            echo "$ts - No suitable engine available for '.$ext_lower' (need $need). Skipping."
            continue
        fi
    else
        chosen_engine="$engine"
        if [[ "$chosen_engine" == "guppy" && "$ext_lower" != "fast5" ]]; then
            echo "$ts - Engine forced to 'guppy' but file is '.$ext_lower'. Skipping."
            continue
        fi
        if [[ "$chosen_engine" == "dorado" && "$ext_lower" != "pod5" ]]; then
            echo "$ts - Engine forced to 'dorado' but file is '.$ext_lower'. Skipping."
            continue
        fi
    fi

    tmp_dir="$save_dir/tmp${batch}"
    out_dir="$save_dir/basecalled_fastq${batch}"
    mkdir -p "$tmp_dir" "$out_dir"

    cp -f "$path" "$tmp_dir/"

    if [[ "$chosen_engine" == "guppy" ]]; then
        echo "$ts - [Guppy] Basecalling batch $batch ..."
        set +e
        "$guppy_basecaller" \
            -i "$tmp_dir" \
            -s "$out_dir" \
            --flowcell "$flowcell" \
            --kit "$kit" \
            --compress_fastq \
            -x "$cuda_device" \
            --model "$model"
        rc=$?
        set -e
        if [[ $rc -ne 0 ]]; then
            echo "$ts - Error: Guppy basecalling failed for batch $batch (rc=$rc)."
            rm -rf "$tmp_dir"
            batch=$((batch + 1))
            continue
        fi

        if [[ -d "$out_dir/pass" ]]; then
            move_pass_fastqs "$out_dir/pass" "$save_dir/pass_fastq"
        else
            move_pass_fastqs "$out_dir" "$save_dir/pass_fastq"
        fi
        rm -rf "$tmp_dir"
        echo "$ts - [Guppy] Batch $batch done."

    elif [[ "$chosen_engine" == "dorado" ]]; then
        echo "$ts - [Dorado] Basecalling batch $batch ..."
        out_fastq_gz="$out_dir/reads.fastq.gz"
        set +e
        "$dorado_bin" basecaller "$dorado_model" "$tmp_dir" \
            --emit-fastq \
            -x "$cuda_device" \
            | gzip > "$out_fastq_gz"
        rc=$?
        set -e
        if [[ $rc -ne 0 ]]; then
            echo "$ts - Error: Dorado basecalling failed for batch $batch (rc=$rc)."
            rm -rf "$tmp_dir"
            batch=$((batch + 1))
            continue
        fi

        mv "$out_fastq_gz" "$save_dir/pass_fastq/"
        rm -rf "$tmp_dir"
        echo "$ts - [Dorado] Batch $batch done."
    fi

    batch=$((batch + 1))
done
