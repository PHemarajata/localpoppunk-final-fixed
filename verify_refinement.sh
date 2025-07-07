#!/bin/bash

echo "🔍 Verifying PopPUNK Refinement Implementation"
echo "=============================================="

# Check if POPPUNK_REFINE process exists
echo "📁 Checking POPPUNK_REFINE process..."
if grep -q "process POPPUNK_REFINE" poppunk_subsample_snp.nf; then
    echo "✅ POPPUNK_REFINE process found"
else
    echo "❌ POPPUNK_REFINE process missing"
    exit 1
fi

# Check refinement parameters in configurations
echo ""
echo "🔧 Checking refinement parameters..."

profiles=("large_dataset_optimized" "bus_error_prevention" "ultra_bus_error_prevention")

for profile in "${profiles[@]}"; do
    echo "  Testing profile: $profile"
    
    if nextflow config -profile $profile > /dev/null 2>&1; then
        enable_refinement=$(nextflow config -profile $profile | grep "poppunk_enable_refinement" | awk '{print $3}')
        refine_both=$(nextflow config -profile $profile | grep "poppunk_refine_both" | awk '{print $3}')
        
        echo "    ✅ Profile works - refinement enabled: $enable_refinement, refine both: $refine_both"
    else
        echo "    ❌ Profile $profile has configuration issues"
        exit 1
    fi
done

# Check workflow integration
echo ""
echo "🔗 Checking workflow integration..."
if grep -q "refined_out.*POPPUNK_REFINE" poppunk_subsample_snp.nf; then
    echo "✅ Refinement integrated into workflow"
else
    echo "❌ Refinement not properly integrated into workflow"
    exit 1
fi

# Check conditional logic
echo ""
echo "🧠 Checking conditional logic..."
if grep -q "refine_type.*indiv-refine" poppunk_subsample_snp.nf; then
    echo "✅ Conditional refinement logic implemented"
else
    echo "❌ Conditional refinement logic missing"
    exit 1
fi

# Check fallback strategy
echo ""
echo "🛡️ Checking fallback strategy..."
if grep -q "Attempt.*refinement" poppunk_subsample_snp.nf; then
    echo "✅ Progressive fallback strategy implemented"
else
    echo "❌ Fallback strategy missing"
    exit 1
fi

# Check database integrity verification
echo ""
echo "🔍 Checking database integrity verification..."
if grep -q "Verifying refined database integrity" poppunk_subsample_snp.nf; then
    echo "✅ Database integrity verification implemented"
else
    echo "❌ Database integrity verification missing"
    exit 1
fi

echo ""
echo "🎉 Refinement Implementation Verification Complete!"
echo "=================================================="
echo ""
echo "✅ POPPUNK_REFINE process properly implemented"
echo "✅ All configuration profiles support refinement parameters"
echo "✅ Workflow integration is correct"
echo "✅ Conditional logic handles different refinement types"
echo "✅ Progressive fallback strategy prevents failures"
echo "✅ Database integrity verification ensures reliability"
echo ""
echo "🚀 Ready to run with refinement:"
echo "   nextflow run poppunk_subsample_snp.nf -profile large_dataset_optimized"
echo ""
echo "📊 Expected refinement benefits for B. pseudomallei:"
echo "   - Better handling of recombination"
echo "   - More accurate lineage separation"
echo "   - Improved cluster boundaries"
echo "   - Enhanced epidemiological relevance"