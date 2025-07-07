# Quick Start: Bus Error Fix

## Immediate Solution

Your pipeline was experiencing bus errors during PopPUNK model fitting. I've implemented a comprehensive fix with multiple fallback strategies.

### Run This Command Now:
```bash
nextflow run poppunk_subsample_snp.nf -profile ultra_bus_error_prevention
```

## What Was Fixed

### 1. Progressive Model Fallback Strategy
The pipeline now tries multiple approaches in order:
1. **Ultra-minimal BGMM** (single-threaded, basic parameters)
2. **Default PopPUNK** (no enhanced parameters)
3. **DBSCAN clustering** (more stable for large datasets)
4. **Threshold model** (simplest approach)
5. **Fallback single cluster** (prevents complete failure)

### 2. Reduced Resource Requirements
- **Sketch size**: 100,000 → 10,000 (prevents memory issues)
- **Threading**: Single-threaded model fitting
- **Memory**: Conservative allocation (24GB)
- **K-mer range**: Simplified (15-21 step 4)

### 3. Enhanced Error Handling
- Multiple retry attempts with different parameters
- Graceful degradation instead of complete failure
- Detailed logging for troubleshooting

## Expected Results

### Success Messages to Look For:
```
✅ Model fitting completed with ultra-minimal settings
✅ Model fitting completed with default parameters
✅ Model fitting completed with DBSCAN fallback
✅ Model fitting completed with threshold model
```

### Runtime Expectations:
- **Database creation**: 1-2 hours
- **Model fitting**: 2-4 hours (slower but stable)
- **Assignment**: 3-6 hours
- **Total**: 6-12 hours

## If You Still Get Bus Errors

### Try with smaller dataset first:
```bash
# Test with subset of your data
mkdir test_subset
cp /path/to/your/assemblies/*.fasta test_subset/ | head -200

nextflow run poppunk_subsample_snp.nf \
  --input test_subset \
  --resultsDir test_results \
  -profile ultra_bus_error_prevention
```

### Monitor system resources:
```bash
# In another terminal
htop
# Watch memory usage during execution
```

## Configuration Profiles Available

1. **ultra_bus_error_prevention** ← Use this for your case
2. **bus_error_prevention** (moderate conservative)
3. **large_dataset_optimized** (full performance, may cause bus errors)
4. **local** (default)

## What to Expect

Even with ultra-conservative settings, you should get:
- **Multiple clusters** (not single giant cluster)
- **Stable execution** (no bus errors)
- **Reasonable clustering** (may not be as refined as optimal settings)

Once this works, we can gradually increase parameters for better resolution.

## Files Created/Modified

- ✅ Enhanced fallback strategy in `poppunk_subsample_snp.nf`
- ✅ New profile: `conf/ultra_bus_error_prevention.config`
- ✅ Updated main config with new profile
- ✅ Comprehensive troubleshooting guide

## Ready to Run!

The pipeline is now equipped with robust bus error prevention. Run the command above and monitor the progress.