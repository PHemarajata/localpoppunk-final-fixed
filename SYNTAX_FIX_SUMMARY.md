# PopPUNK Syntax Error Fix

## Problem Identified
The pipeline was failing with the error:
```
poppunk: error: unrecognized arguments: --run-qc
```

## Root Cause
The `--run-qc` flag was incorrectly added to `poppunk --fit-model` commands. According to PopPUNK documentation and the help output, `--run-qc` is only valid for `poppunk_assign` commands, not for model fitting.

## Fix Applied
Removed `--run-qc` flag from all `poppunk --fit-model` commands:

### Before (INCORRECT):
```bash
poppunk --fit-model bgmm --ref-db poppunk_db \
        --output poppunk_fit --threads $model_threads \
        --min-k ${params.poppunk_min_k} \
        --max-k ${params.poppunk_max_k} \
        --k-step ${params.poppunk_k_step} \
        --max-a-dist ${params.poppunk_max_a_dist} \
        --reciprocal-only \
        --count-unique-distances \
        --run-qc \                    # ❌ INVALID FOR FIT-MODEL
        --max-search-depth ${params.poppunk_max_search} \
        --K ${params.poppunk_K}
```

### After (CORRECT):
```bash
poppunk --fit-model bgmm --ref-db poppunk_db \
        --output poppunk_fit --threads $model_threads \
        --min-k ${params.poppunk_min_k} \
        --max-k ${params.poppunk_max_k} \
        --k-step ${params.poppunk_k_step} \
        --max-a-dist ${params.poppunk_max_a_dist} \
        --reciprocal-only \
        --count-unique-distances \
        --max-search-depth ${params.poppunk_max_search} \
        --K ${params.poppunk_K}
```

## QC Implementation (CORRECT)
QC is properly implemented in the assignment step:
```bash
poppunk_assign --query staged_chunk_files.list \
               --db ${db_dir} \
               --output poppunk_chunk_${chunk_id} \
               --threads ${task.cpus} \
               --write-references \
               --run-qc \              # ✅ VALID FOR ASSIGN
               --max-zero-dist ${params.poppunk_max_zero_dist} \
               --max-merge ${params.poppunk_max_merge} \
               --length-sigma ${params.poppunk_length_sigma}
```

## Files Modified
- `poppunk_subsample_snp.nf` - Removed `--run-qc` from model fitting commands

## Status
✅ **FIXED** - Pipeline should now run without syntax errors

The enhanced B. pseudomallei clustering parameters are still in place:
- Large sketch size (100,000)
- Enhanced k-mer range (15-31 step 2)  
- More mixture components (K=4)
- Tighter accessory distance (0.55)
- QC enabled during assignment step

## Next Steps
Run the pipeline again with the corrected syntax:
```bash
nextflow run poppunk_subsample_snp.nf -profile large_dataset_optimized
```