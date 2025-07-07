# PopPUNK Bus Error Troubleshooting Guide

## Problem
Your pipeline is experiencing persistent bus errors during PopPUNK model fitting:
```
Bus error (core dumped) poppunk --fit-model bgmm --ref-db poppunk_db
```

## Root Causes
Bus errors in PopPUNK typically occur due to:
1. **Memory access violations** with large sketch sizes
2. **Dataset size** exceeding memory capacity
3. **Thread contention** in multi-threaded operations
4. **Hardware limitations** with large genomic datasets

## Immediate Solution

### Use Ultra-Conservative Profile
```bash
nextflow run poppunk_subsample_snp.nf -profile ultra_bus_error_prevention
```

This profile implements:
- **Reduced sketch size**: 100,000 → 10,000
- **Single-threaded processing**: Prevents thread contention
- **Simplified parameters**: Minimal k-mer range and search depth
- **Forced subsampling**: Reduces dataset size
- **Multiple model fallbacks**: BGMM → DBSCAN → Threshold

## Progressive Troubleshooting

### Step 1: Reduce Dataset Size
If you have 3,500 genomes, try with a smaller subset first:
```bash
# Test with ~500 genomes
head -500 /path/to/your/assemblies/*.fasta
```

### Step 2: Check System Resources
```bash
# Monitor memory usage during run
htop

# Check available memory
free -h

# Check for memory errors in system logs
dmesg | grep -i "memory\|oom"
```

### Step 3: Hardware Considerations
- **RAM**: Large datasets need 32-64GB+ RAM
- **CPU**: Single-threaded processing is more stable
- **Storage**: Ensure sufficient disk space for intermediate files

## Configuration Hierarchy (Most to Least Conservative)

### 1. Ultra Bus Error Prevention (Recommended for your case)
```bash
nextflow run poppunk_subsample_snp.nf -profile ultra_bus_error_prevention
```
- **Sketch size**: 10,000
- **Threading**: Single-threaded
- **Model**: Multiple fallbacks
- **Dataset**: Forced subsampling

### 2. Bus Error Prevention
```bash
nextflow run poppunk_subsample_snp.nf -profile bus_error_prevention
```
- **Sketch size**: 100,000
- **Threading**: Limited (4-8 threads)
- **Model**: Conservative parameters

### 3. Large Dataset Optimized
```bash
nextflow run poppunk_subsample_snp.nf -profile large_dataset_optimized
```
- **Sketch size**: 100,000
- **Threading**: Full utilization
- **Model**: Enhanced parameters

## Model Fallback Strategy

The updated pipeline now uses a progressive fallback:

1. **BGMM with minimal parameters** (single-threaded)
2. **Default PopPUNK parameters** (if enhanced parameters fail)
3. **DBSCAN clustering** (more stable for large datasets)
4. **Threshold model** (simplest approach)
5. **Fallback single cluster** (prevents pipeline failure)

## Expected Behavior

### With Ultra-Conservative Profile:
- **Runtime**: 12-24 hours (slower but stable)
- **Clustering**: Basic resolution (may not separate all lineages)
- **Stability**: High (should complete without bus errors)
- **Output**: Functional clustering results

### Success Indicators:
```
✅ Model fitting completed with ultra-minimal settings
✅ Model fitting completed with default parameters  
✅ Model fitting completed with DBSCAN fallback
✅ Model fitting completed with threshold model
```

## If Bus Errors Persist

### 1. Reduce Dataset Further
```bash
# Use only 100-200 genomes for testing
ls /path/to/assemblies/*.fasta | head -200
```

### 2. Check PopPUNK Version
```bash
docker run --rm staphb/poppunk:2.7.5 poppunk --version
```

### 3. Alternative Approach: Manual Subsampling
```bash
# Create a small test dataset
mkdir test_dataset
cp /path/to/assemblies/*.fasta test_dataset/ | head -100

# Run on test dataset
nextflow run poppunk_subsample_snp.nf \
  --input test_dataset \
  -profile ultra_bus_error_prevention
```

### 4. Hardware Upgrade Considerations
For 3,500 B. pseudomallei genomes:
- **Minimum**: 32GB RAM, 8 cores
- **Recommended**: 64GB RAM, 16+ cores
- **Optimal**: 128GB RAM, 32+ cores

## Alternative Clustering Methods

If PopPUNK continues to fail, consider:

### 1. FastANI + Clustering
```bash
# Calculate ANI distances
fastani --ql genome_list.txt --rl genome_list.txt -o ani_results.txt

# Cluster based on ANI threshold (e.g., 95%)
python cluster_ani.py ani_results.txt 0.95
```

### 2. Mash + Hierarchical Clustering
```bash
# Use existing Mash distances
mash dist sketches.msh sketches.msh > distances.txt

# Hierarchical clustering in R/Python
```

## Monitoring Progress

### Check Pipeline Status:
```bash
tail -f .nextflow.log
```

### Monitor Resource Usage:
```bash
# CPU and memory
htop

# Disk usage
df -h

# Process-specific monitoring
ps aux | grep poppunk
```

## Success Metrics

Even with conservative settings, you should achieve:
- **Multiple clusters** (not single giant cluster)
- **Reasonable runtime** (12-24 hours)
- **Stable execution** (no bus errors)
- **Meaningful results** (biologically relevant groupings)

## Next Steps After Success

Once the ultra-conservative profile works:
1. **Analyze results** to understand cluster distribution
2. **Gradually increase parameters** if more resolution needed
3. **Scale up dataset size** incrementally
4. **Consider hardware upgrades** for full-resolution analysis

The goal is to get functional results first, then optimize for better resolution.