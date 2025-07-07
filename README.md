# PopPUNK Local Pipeline

A Nextflow pipeline for bacterial genome clustering using PopPUNK (Population Partitioning Using Nucleotide K-mers).

## Overview

This pipeline performs intelligent subsampling and clustering of bacterial genomes using:
- **MASH** for k-mer sketching and pre-clustering
- **PopPUNK 2.7.5** for detailed clustering and population structure analysis
- **Intelligent subsampling** to handle large datasets efficiently

## Pipeline Workflow

1. **VALIDATE_FASTA** - Validates input FASTA files
2. **MASH_SKETCH** - Creates k-mer sketches
3. **MASH_DIST** - Calculates pairwise distances
4. **BIN_SUBSAMPLE** - Intelligent subsampling (30% of each component)
5. **POPPUNK_MODEL** - Builds PopPUNK clustering model
6. **POPPUNK_ASSIGN** - Assigns all genomes to clusters
7. **SUMMARY_REPORT** - Generates comprehensive analysis report

## Quick Start

1. **Configure input/output paths** in `nextflow.config`:
   ```groovy
   params {
     input = '/path/to/your/fasta/files'
     resultsDir = '/path/to/results'
   }
   ```

2. **Run the pipeline**:
   ```bash
   # Default mode (with intelligent subsampling)
   nextflow run poppunk_subsample_snp.nf
   
   # Use ALL samples for PopPUNK modeling (no subsampling)
   nextflow run poppunk_subsample_snp.nf -c conf/use_all_samples.config
   
   # Or set the parameter directly
   nextflow run poppunk_subsample_snp.nf --use_all_samples true
   ```

3. **Test with segfault fixes**:
   ```bash
   ./test_segfault_fixes.sh
   ```

## Key Features

- ✅ **Segmentation fault fixes** - Resolved PopPUNK 2.7.5 stability issues
- ✅ **Flexible sampling modes** - Choose between intelligent subsampling or using all samples
- ✅ **Intelligent subsampling** - Handles large datasets (450+ genomes) efficiently
- ✅ **Use all samples option** - Include every sample for PopPUNK modeling when needed
- ✅ **Graceful fallbacks** - Progressive error recovery
- ✅ **Comprehensive validation** - Input file quality control
- ✅ **Docker containerization** - Reproducible execution

## Sampling Modes

The pipeline supports two modes for PopPUNK modeling:

### 1. Intelligent Subsampling (Default)
- **When to use**: Large datasets (>100 genomes) where computational efficiency is important
- **How it works**: 
  - Uses MASH to identify similar genomes
  - Groups genomes into connected components based on similarity
  - Selects 15% of genomes from each component (min 10, max 100 per component)
  - Reduces computational load while maintaining population structure
- **Parameter**: `use_all_samples = false` (default)

### 2. Use All Samples
- **When to use**: 
  - Smaller datasets where you want maximum resolution
  - When every sample is important for your analysis
  - When you have sufficient computational resources
- **How it works**: 
  - Skips MASH distance calculation (saves time)
  - Uses every validated sample for PopPUNK modeling
  - Provides maximum clustering resolution
- **Parameter**: `use_all_samples = true`

### Choosing the Right Mode
- **Use subsampling** for datasets >200 genomes or when computational resources are limited
- **Use all samples** for smaller datasets (<100 genomes) or when maximum resolution is needed
- **Consider your resources**: Using all samples requires more memory and CPU time

## Configuration

### Resource Settings
```groovy
params {
  threads = 16        // Optimized to prevent segfaults
  ram = '200 GB'      // Memory allocation
}
```

### PopPUNK Settings
```groovy
params {
  // MASH pre-clustering (only used when subsampling)
  mash_k = 21
  mash_s = 1000
  mash_thresh = 0.001
  
  // Sampling mode control
  use_all_samples = false  // Set to true to use all samples instead of subsampling
  
  // PopPUNK stability fixes
  poppunk_stable = false  // Disabled to prevent segfaults
  poppunk_reciprocal = true
  poppunk_max_search = 10
}
```

## Troubleshooting

### Segmentation Faults
- **Fixed**: Thread count reduced from 48 to 16
- **Fixed**: Disabled `--stable core` option
- **Fixed**: Added graceful fallback strategies

### Large Datasets
- Uses intelligent subsampling (30% of each component)
- Minimum 25, maximum 200 representatives per cluster
- Progressive fallback to single-thread processing

## Output Files

- `full_assign.csv` - Cluster assignments for all genomes
- `pipeline_summary.txt` - Analysis summary and statistics
- `validation_report.txt` - Input file validation results

## Documentation

- `SEGFAULT_FIXES.md` - Detailed segmentation fault solutions
- `SEGFAULT_SOLUTION_SUMMARY.md` - Complete fix overview
- `IMPROVEMENTS.md` - Pipeline enhancement history
- Various fix documentation files for specific issues

## Requirements

- **Nextflow** 20.04+
- **Docker** or **Singularity**
- **8+ GB RAM** (200+ GB recommended for large datasets)
- **8+ CPUs** (16+ recommended)

## Citation

If you use this pipeline, please cite:
- **PopPUNK**: Lees et al. (2019) Genome Research
- **MASH**: Ondov et al. (2016) Genome Biology
- **Nextflow**: Di Tommaso et al. (2017) Nature Biotechnology

---

**Status**: ✅ Production ready with segmentation fault fixes applied
**Last Updated**: 2024-06-24
**Version**: 2.7.5 (PopPUNK) with stability patches