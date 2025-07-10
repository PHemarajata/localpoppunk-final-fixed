#!/bin/bash

# Default values
INPUT_DIR="./input"
RESULTS_DIR="./results"
PROFILE="dgx_a100"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -i|--input)
      INPUT_DIR="$2"
      shift 2
      ;;
    -o|--output)
      RESULTS_DIR="$2"
      shift 2
      ;;
    -p|--profile)
      PROFILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

# Create results directory if it doesn't exist
mkdir -p "$RESULTS_DIR/reports"

# Run the pipeline
nextflow run poppunk_subsample_snp.nf \
  -profile "$PROFILE" \
  --input "$INPUT_DIR" \
  --resultsDir "$RESULTS_DIR"
