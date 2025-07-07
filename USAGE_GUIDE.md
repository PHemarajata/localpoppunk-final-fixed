# Usage Guide for Enhanced B. pseudomallei PopPUNK Pipeline

## Quick Start

For your 3,500 B. pseudomallei sequences, use one of these optimized profiles:

### Option 1: Large Dataset Optimized (Recommended)
```bash
nextflow run poppunk_subsample_snp.nf -profile large_dataset_optimized \
  --input_dir /path/to/your/assemblies \
  --output_dir results_enhanced
```

### Option 2: Bus Error Prevention (If stability issues occur)
```bash
nextflow run poppunk_subsample_snp.nf -profile bus_error_prevention \
  --input_dir /path/to/your/assemblies \
  --output_dir results_stable
```

## Key Improvements Made

1. **10x larger sketch size** (100,000 vs 1,000) for better B. pseudomallei resolution
2. **Enhanced k-mer range** (15-31 step 2) for higher resolution clustering
3. **More mixture components** (K=4 vs K=2) for better cluster separation
4. **PopPUNK QC filtering** to remove problematic genomes
5. **Optimized for your hardware** (22 cores, 64GB RAM)

## Expected Runtime

- **Database creation**: ~2-4 hours for 3,500 genomes
- **Model fitting**: ~4-8 hours with enhanced parameters
- **Assignment**: ~2-3 hours in chunks
- **Total**: ~8-15 hours (vs single cluster in minutes before)

## Monitoring Progress

1. **Check clustering progress**:
   ```bash
   tail -f .nextflow.log
   ```

2. **View distance plots** (after database creation):
   ```bash
   poppunk_visual --db results_enhanced/poppunk_db
   ```

3. **Check QC results**:
   ```bash
   ls results_enhanced/poppunk_db*qc*
   ```

## Troubleshooting

### Still getting single cluster?
1. Further tighten accessory distance:
   ```bash
   --poppunk_max_a_dist 0.5  # or 0.45
   ```

2. Increase mixture components:
   ```bash
   --poppunk_K 5  # or 6
   ```

### Memory issues?
Use bus_error_prevention profile with reduced resources:
```bash
nextflow run poppunk_subsample_snp.nf -profile bus_error_prevention
```

### Bus errors/crashes?
1. Check system resources: `htop`
2. Reduce parallel chunks: `--max_forks 2`
3. Use single-threaded fallback (automatic in pipeline)

## Expected Results

- **Multiple clusters** instead of single giant cluster
- **Biologically meaningful lineages** (similar to Thai B. pseudomallei study)
- **Clean core vs accessory separation** in distance plots
- **Stable processing** without bus errors

## Files Generated

- `poppunk_db/` - Enhanced PopPUNK database
- `poppunk_fit/` - Model with improved parameters
- `*_clusters.csv` - Cluster assignments
- `*_qc_filtered.list` - QC-filtered genome list (if applicable)
- Distance plots and visualizations