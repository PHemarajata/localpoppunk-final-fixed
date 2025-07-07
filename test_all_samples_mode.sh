#!/bin/bash

# Test script to verify the use_all_samples functionality
# This script tests both modes of the pipeline

echo "Testing PopPUNK pipeline with both sampling modes..."

# Test 1: Default subsampling mode
echo "=== Test 1: Default subsampling mode ==="
echo "Running: nextflow run poppunk_subsample_snp.nf --use_all_samples false -preview"
nextflow run poppunk_subsample_snp.nf --use_all_samples false -preview

echo ""

# Test 2: Use all samples mode
echo "=== Test 2: Use all samples mode ==="
echo "Running: nextflow run poppunk_subsample_snp.nf --use_all_samples true -preview"
nextflow run poppunk_subsample_snp.nf --use_all_samples true -preview

echo ""

# Test 3: Using configuration file
echo "=== Test 3: Using configuration file ==="
echo "Running: nextflow run poppunk_subsample_snp.nf -c conf/use_all_samples.config -preview"
nextflow run poppunk_subsample_snp.nf -c conf/use_all_samples.config -preview

echo ""
echo "All tests completed. Check the output above for any errors."
echo ""
echo "To run the pipeline with all samples:"
echo "  nextflow run poppunk_subsample_snp.nf --use_all_samples true"
echo ""
echo "To run the pipeline with subsampling (default):"
echo "  nextflow run poppunk_subsample_snp.nf"