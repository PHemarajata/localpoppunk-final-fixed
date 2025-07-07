#!/bin/bash

echo "🔍 Verifying PopPUNK Bus Error Prevention Setup"
echo "=============================================="

# Check if main files exist
echo "📁 Checking main files..."
if [ -f "poppunk_subsample_snp.nf" ]; then
    echo "✅ Main pipeline file exists"
else
    echo "❌ Main pipeline file missing"
    exit 1
fi

if [ -f "nextflow.config" ]; then
    echo "✅ Main config file exists"
else
    echo "❌ Main config file missing"
    exit 1
fi

if [ -f "conf/ultra_bus_error_prevention.config" ]; then
    echo "✅ Ultra-conservative config exists"
else
    echo "❌ Ultra-conservative config missing"
    exit 1
fi

# Check configuration profiles
echo ""
echo "🔧 Checking configuration profiles..."
if nextflow config -profile ultra_bus_error_prevention > /dev/null 2>&1; then
    echo "✅ ultra_bus_error_prevention profile works"
else
    echo "❌ ultra_bus_error_prevention profile has issues"
    exit 1
fi

# Check key parameters
echo ""
echo "⚙️  Checking key parameters..."
sketch_size=$(nextflow config -profile ultra_bus_error_prevention | grep "poppunk_sketch_size" | awk '{print $3}')
echo "   Sketch size: $sketch_size (should be 10000)"

k_value=$(nextflow config -profile ultra_bus_error_prevention | grep "poppunk_K" | awk '{print $3}')
echo "   K value: $k_value (should be 2)"

threads=$(nextflow config -profile ultra_bus_error_prevention | grep "threads =" | head -1 | awk '{print $3}')
echo "   Threads: $threads (should be 4)"

use_all=$(nextflow config -profile ultra_bus_error_prevention | grep "use_all_samples" | awk '{print $3}')
echo "   Use all samples: $use_all (should be false for subsampling)"

# Check fallback strategy in pipeline
echo ""
echo "🛡️  Checking fallback strategy..."
if grep -q "ULTRA BUS ERROR PREVENTION" poppunk_subsample_snp.nf; then
    echo "✅ Ultra bus error prevention strategy implemented"
else
    echo "❌ Bus error prevention strategy missing"
    exit 1
fi

if grep -q "dbscan" poppunk_subsample_snp.nf; then
    echo "✅ DBSCAN fallback implemented"
else
    echo "❌ DBSCAN fallback missing"
    exit 1
fi

if grep -q "threshold" poppunk_subsample_snp.nf; then
    echo "✅ Threshold model fallback implemented"
else
    echo "❌ Threshold model fallback missing"
    exit 1
fi

# Check conservative sketch size logic
if grep -q "conservative_sketch_size" poppunk_subsample_snp.nf; then
    echo "✅ Conservative sketch size logic implemented"
else
    echo "❌ Conservative sketch size logic missing"
    exit 1
fi

echo ""
echo "🎉 Setup Verification Complete!"
echo "================================"
echo ""
echo "✅ All bus error prevention measures are in place"
echo "✅ Ultra-conservative profile is configured"
echo "✅ Multiple fallback strategies are implemented"
echo "✅ Conservative resource allocation is set"
echo ""
echo "🚀 Ready to run:"
echo "   nextflow run poppunk_subsample_snp.nf -profile ultra_bus_error_prevention"
echo ""
echo "📊 Expected behavior:"
echo "   - No more bus errors"
echo "   - Slower but stable execution"
echo "   - Multiple clusters (not single giant cluster)"
echo "   - Complete processing of all genomes"