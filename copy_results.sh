#!/bin/bash

# Script to manually copy results when publishDir fails due to permission issues
# Usage: ./copy_results.sh

echo "🔧 Manual Results Copy Script"
echo "=============================="

# Find the work directory with the results
WORK_DIR=$(find work -name "full_assign.csv" -type f 2>/dev/null | head -1)

if [ -z "$WORK_DIR" ]; then
    echo "❌ Could not find full_assign.csv in work directory"
    echo "   Make sure the pipeline has completed the MERGE_CHUNK_RESULTS step"
    exit 1
fi

WORK_DIR=$(dirname "$WORK_DIR")
echo "📁 Found results in: $WORK_DIR"

# Set up output directories
RESULTS_DIR="${1:-results}"  # Use first argument or default to 'results'
OUTPUT_DIR="$RESULTS_DIR/poppunk_full"
SUMMARY_DIR="$RESULTS_DIR/summary"

echo "📂 Creating output directories..."
mkdir -p "$OUTPUT_DIR"
mkdir -p "$SUMMARY_DIR"

# Copy the main results file
if [ -f "$WORK_DIR/full_assign.csv" ]; then
    echo "📋 Copying full_assign.csv..."
    cp "$WORK_DIR/full_assign.csv" "$OUTPUT_DIR/"
    chmod 644 "$OUTPUT_DIR/full_assign.csv"
    echo "✅ Copied: $OUTPUT_DIR/full_assign.csv"
    
    # Show basic stats
    total_samples=$(tail -n +2 "$OUTPUT_DIR/full_assign.csv" | wc -l)
    unique_clusters=$(tail -n +2 "$OUTPUT_DIR/full_assign.csv" | cut -d',' -f2 | sort -u | wc -l)
    echo "   📊 Total samples: $total_samples"
    echo "   🎯 Unique clusters: $unique_clusters"
else
    echo "❌ full_assign.csv not found in work directory"
fi

# Look for summary report in work directories
SUMMARY_WORK=$(find work -name "pipeline_summary.txt" -type f 2>/dev/null | head -1)
if [ -n "$SUMMARY_WORK" ]; then
    echo "📋 Copying pipeline_summary.txt..."
    cp "$SUMMARY_WORK" "$SUMMARY_DIR/"
    chmod 644 "$SUMMARY_DIR/pipeline_summary.txt"
    echo "✅ Copied: $SUMMARY_DIR/pipeline_summary.txt"
fi

# Look for other important files
echo ""
echo "🔍 Looking for other result files..."

# Model files
MODEL_WORK=$(find work -name "poppunk_db" -type d 2>/dev/null | head -1)
if [ -n "$MODEL_WORK" ]; then
    echo "📁 Found PopPUNK model directory: $MODEL_WORK"
    MODEL_OUTPUT="$RESULTS_DIR/poppunk_model"
    mkdir -p "$MODEL_OUTPUT"
    echo "📋 Copying PopPUNK model files..."
    cp -r "$MODEL_WORK"/* "$MODEL_OUTPUT/" 2>/dev/null || true
    echo "✅ Copied model files to: $MODEL_OUTPUT"
fi

# Validation files
VALIDATION_WORK=$(find work -name "validation_report.txt" -type f 2>/dev/null | head -1)
if [ -n "$VALIDATION_WORK" ]; then
    echo "📋 Copying validation report..."
    VALIDATION_OUTPUT="$RESULTS_DIR/validation"
    mkdir -p "$VALIDATION_OUTPUT"
    cp "$VALIDATION_WORK" "$VALIDATION_OUTPUT/"
    chmod 644 "$VALIDATION_OUTPUT/validation_report.txt"
    echo "✅ Copied: $VALIDATION_OUTPUT/validation_report.txt"
fi

# Chunk results
CHUNK_WORK=$(find work -name "chunk_*_assign.csv" -type f 2>/dev/null | head -1)
if [ -n "$CHUNK_WORK" ]; then
    CHUNK_DIR=$(dirname "$CHUNK_WORK")
    echo "📁 Found chunk results in: $CHUNK_DIR"
    CHUNK_OUTPUT="$RESULTS_DIR/poppunk_chunks"
    mkdir -p "$CHUNK_OUTPUT"
    echo "📋 Copying chunk result files..."
    find work -name "chunk_*_assign.csv" -type f -exec cp {} "$CHUNK_OUTPUT/" \; 2>/dev/null
    chmod 644 "$CHUNK_OUTPUT"/*.csv 2>/dev/null || true
    chunk_count=$(ls "$CHUNK_OUTPUT"/chunk_*_assign.csv 2>/dev/null | wc -l)
    echo "✅ Copied $chunk_count chunk result files to: $CHUNK_OUTPUT"
fi

echo ""
echo "🎉 Manual copy completed!"
echo "📂 Results are now available in: $RESULTS_DIR"
echo ""
echo "📋 Main results file: $OUTPUT_DIR/full_assign.csv"
if [ -f "$SUMMARY_DIR/pipeline_summary.txt" ]; then
    echo "📊 Summary report: $SUMMARY_DIR/pipeline_summary.txt"
fi
echo ""
echo "💡 You can now analyze your PopPUNK clustering results!"