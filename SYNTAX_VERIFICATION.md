# PopPUNK Syntax Verification and Corrections

## Issues Found and Fixed

### 1. K-mer Parameter Names ✅ FIXED
**Issue**: Used `--max-kmer` instead of `--max-k`
**Fix**: Changed to correct PopPUNK parameter names:
- `poppunk_max_kmer` → `poppunk_max_k`
- Command: `--max-kmer` → `--max-k`

### 2. QC Implementation ✅ FIXED
**Issue**: Incorrectly implemented separate `poppunk_qc` command
**Fix**: QC parameters are used with `poppunk_assign --run-qc` flag:
- Removed separate `poppunk_qc` command
- Added `--run-qc` flag to `poppunk_assign` when `poppunk_run_qc = true`
- QC parameters (`--max-zero-dist`, `--max-merge`, `--length-sigma`) used with assignment

### 3. Verified Correct Syntax

#### Database Creation ✅ CORRECT
```bash
poppunk --create-db --r-files staged_files.list \
        --sketch-size ${params.poppunk_sketch_size} \
        --output poppunk_db --threads ${task.cpus}
```

#### Model Fitting ✅ CORRECT
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

#### Query Assignment ✅ CORRECT
```bash
poppunk_assign --query staged_chunk_files.list \
               --db ${db_dir} \
               --output poppunk_chunk_${chunk_id} \
               --threads ${task.cpus} \
               --write-references \
               --run-qc \
               --max-zero-dist ${params.poppunk_max_zero_dist} \
               --max-merge ${params.poppunk_max_merge} \
               --length-sigma ${params.poppunk_length_sigma}
```

#### Mash Commands ✅ CORRECT
```bash
# Sketching
mash sketch -p ${task.cpus} -k ${params.mash_k} -s ${params.mash_s} \
            -o mash.msh -l all_files.list

# Distance calculation
mash dist -p ${task.cpus} ${msh} ${msh} > mash.dist
```

## Parameter Verification

### Core PopPUNK Parameters ✅ VERIFIED
- `--min-k 15` - Minimum k-mer size
- `--max-k 31` - Maximum k-mer size (corrected from --max-kmer)
- `--k-step 2` - K-mer step size
- `--sketch-size 100000` - Sketch size for database creation
- `--max-a-dist 0.55` - Maximum accessory distance threshold
- `--K 4` - Number of mixture components
- `--reciprocal-only` - Use reciprocal distances only
- `--count-unique-distances` - Count unique distances
- `--max-search-depth 15` - Maximum search depth

### QC Parameters ✅ VERIFIED
- `--run-qc` - Enable QC during assignment
- `--max-zero-dist 1` - Maximum zero distances allowed
- `--max-merge 3` - Maximum merge operations
- `--length-sigma 2` - Genome length outlier detection

### Mash Parameters ✅ VERIFIED
- `-k 21` - K-mer size for Mash
- `-s 100000` - Sketch size for Mash
- `-p ${threads}` - Number of threads

## Configuration Files Updated

All parameter names corrected in:
- ✅ `nextflow.config`
- ✅ `conf/bus_error_prevention.config`
- ✅ `conf/large_dataset_optimized.config`
- ✅ `poppunk_subsample_snp.nf`

## Testing

Configuration syntax verified:
```bash
nextflow config -profile large_dataset_optimized | grep poppunk_max_k
# Output: poppunk_max_k = 31 ✅
```

## References

Syntax verified against:
- PopPUNK official documentation: https://poppunk.bacpop.org/
- PopPUNK QC guide: https://poppunk.bacpop.org/qc.html
- PopPUNK sketching guide: https://poppunk.bacpop.org/sketching.html
- PopPUNK model fitting guide: https://poppunk.bacpop.org/model_fitting.html
- PopPUNK query assignment guide: https://poppunk.bacpop.org/query_assignment.html

## Status: ✅ ALL SYNTAX ISSUES RESOLVED

The pipeline now uses correct PopPUNK syntax and parameter names according to the official documentation.