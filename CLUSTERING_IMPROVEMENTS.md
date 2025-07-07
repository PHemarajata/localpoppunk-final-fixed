# PopPUNK Clustering Improvements for B. pseudomallei

## Problem
All 3,500 B. pseudomallei sequences were clustering into a single cluster, indicating insufficient resolution in the PopPUNK parameters.

## Changes Made

### 1. Enhanced K-mer Parameters
- **Increased sketch size**: 1,000 → 100,000 (10x increase for 7Mb B. pseudomallei genome)
- **Improved k-mer range**: Default 15-29 step 4 → 15-31 step 2 (higher resolution)
- **Added parameters**:
  - `poppunk_min_k = 15`
  - `poppunk_max_k = 31` 
  - `poppunk_k_step = 2`
  - `poppunk_sketch_size = 100000`

### 2. Mixture Model Optimization
- **Increased mixture components**: K=2 → K=4 (allows better cluster separation)
- **Tightened accessory distance**: Added `poppunk_max_a_dist = 0.55`
- **Enabled reciprocal fitting**: `poppunk_reciprocal = true`
- **Enabled unique distance counting**: `poppunk_count_unique = true`

### 3. Added PopPUNK QC Process
- **Enabled QC filtering**: `poppunk_run_qc = true`
- **QC parameters**:
  - `--max-zero-dist 0.05`
  - `--max-pi-dist 0.02`
  - `--max-a-dist 0.9`
  - `--max-merge 0`

### 4. Hardware Optimization (22 cores, 64GB RAM)
- **Main threads**: 12 → 16 cores
- **Memory allocation**: 32GB → 48-50GB
- **Chunk processing**: 4 → 6 cores per chunk
- **Chunk memory**: 16GB → 20GB per chunk

## Configuration Files Updated

### 1. `nextflow.config`
- Added new PopPUNK parameters
- Increased Mash sketch size to 100,000
- Optimized resource allocation

### 2. `conf/bus_error_prevention.config`
- Balanced parameters to prevent bus errors while improving clustering
- Added all new k-mer and QC parameters
- Optimized for 22-core, 64GB system

### 3. `conf/large_dataset_optimized.config`
- Enhanced for B. pseudomallei clustering
- Added all new parameters
- Optimized resource allocation for large datasets

### 4. `poppunk_subsample_snp.nf`
- Added PopPUNK QC step before model fitting
- Updated database creation with sketch size parameter
- Enhanced model fitting with new k-mer parameters
- Updated all fallback attempts with improved parameters

## Expected Results

1. **Better cluster separation**: Higher resolution k-mers and larger sketch size should prevent over-clustering
2. **Quality filtering**: QC step removes problematic genomes that can cause cluster merging
3. **Improved model fitting**: More mixture components (K=4) allows better representation of B. pseudomallei diversity
4. **Stable processing**: Optimized resource allocation prevents bus errors while maximizing performance

## Usage

Run with the enhanced configuration:

```bash
# For large datasets (recommended)
nextflow run poppunk_subsample_snp.nf -profile large_dataset_optimized

# For bus error prevention (if stability issues occur)
nextflow run poppunk_subsample_snp.nf -profile bus_error_prevention
```

## Monitoring

1. Check the core vs accessory scatter plot: `poppunk_visual --db poppunk_db`
2. Look for "football-shaped" blob → should now show better separation
3. Monitor QC output for filtered genomes
4. Verify cluster counts are reasonable (not 1 giant cluster)

## Troubleshooting

If still getting single cluster:
1. Further tighten `poppunk_max_a_dist` (try 0.5, then 0.45)
2. Increase `poppunk_K` to 5 or 6
3. Check QC output for problematic genomes
4. Examine distance plots for parameter tuning guidance