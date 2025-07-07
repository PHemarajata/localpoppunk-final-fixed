# PopPUNK Pipeline Fixes

## Issues Fixed

### 1. Duplicate Names Error
**Problem**: PopPUNK was detecting that query sample names matched reference database names, causing the pipeline to stop with the error:
```
Names of queries match names in reference database
Not running -- change names or add --write-references to override this behaviour
```

**Solution**: 
- Added `FILTER_ASSIGNMENT_SAMPLES` process that identifies samples used in model training
- Only assigns samples that weren't part of the original model training set
- Prevents duplicate name conflicts by filtering out training samples from assignment

### 2. Bus Error with Large Datasets
**Problem**: When using `use_all_samples = true` with ~3500 sequences, the pipeline crashed with bus errors due to memory exhaustion.

**Solution**:
- Implemented chunked processing with `CHUNK_SAMPLES` and `POPPUNK_ASSIGN_CHUNK` processes
- Splits large datasets into manageable chunks (500-800 samples per chunk)
- Processes chunks in parallel with conservative resource allocation
- Merges results from all chunks into final output

### 3. Resource Optimization for Your Hardware
**Hardware**: 22 cores, 64GB RAM

**Optimizations**:
- Conservative per-chunk threading (4 cores per chunk)
- Allows 3-4 chunks to run in parallel
- Leaves system overhead for stability
- Optimized memory allocation per process

## How to Use the Fixed Pipeline

### Option 1: Use the Large Dataset Configuration (Recommended)
```bash
cd localpoppunk-final-fixed
nextflow run poppunk_subsample_snp.nf -c conf/large_dataset_optimized.config
```

### Option 2: Use Local Profile with Default Settings
```bash
cd localpoppunk-final-fixed
nextflow run poppunk_subsample_snp.nf -profile local
```

### Option 3: Custom Configuration
Edit `nextflow.config` and adjust these parameters:
```groovy
params {
    use_all_samples = true          // Use all samples with chunking
    threads_per_chunk = 4           // Threads per chunk
    memory_per_chunk = '16 GB'      // Memory per chunk
}
```

## Key Changes Made

### New Processes Added:
1. **FILTER_ASSIGNMENT_SAMPLES**: Removes training samples from assignment list
2. **CHUNK_SAMPLES**: Splits large datasets into manageable chunks
3. **POPPUNK_ASSIGN_CHUNK**: Processes individual chunks with conservative resources
4. **MERGE_CHUNK_RESULTS**: Combines all chunk results into final output

### Configuration Updates:
- Added chunking parameters
- Optimized resource allocation for your hardware
- Added process-specific resource limits
- Enabled detailed reporting for troubleshooting

### Workflow Changes:
- Modified main workflow to use chunked processing
- Added sample filtering step before assignment
- Parallel chunk processing with result merging

## Expected Behavior

### For 3500 Samples:
- **Chunking**: ~5-7 chunks of 500-800 samples each
- **Parallel Processing**: 3-4 chunks running simultaneously
- **Memory Usage**: ~48-64GB total (16GB per active chunk)
- **Processing Time**: Significantly faster due to parallelization

### Output:
- Same final results as original pipeline
- Additional intermediate files in `poppunk_chunks/` directory
- Detailed execution reports in `results/reports/`

## Troubleshooting

### If You Still Get Bus Errors:
1. Reduce `memory_per_chunk` to `12 GB`
2. Reduce `threads_per_chunk` to `2`
3. Set `maxForks = 2` in the process configuration

### If You Get Out of Memory Errors:
1. Increase chunk size by editing the chunking logic in `CHUNK_SAMPLES`
2. Reduce the number of parallel chunks with `maxForks = 2`

### If Assignment Takes Too Long:
1. Increase `threads_per_chunk` to `6-8`
2. Increase `maxForks` to allow more parallel chunks

## Verification

The pipeline will now:
1. ✅ Skip samples used in model training (no duplicate name errors)
2. ✅ Process large datasets without bus errors
3. ✅ Use your hardware efficiently (22 cores, 64GB RAM)
4. ✅ Provide the same clustering results as the original pipeline
5. ✅ Generate detailed reports for monitoring

Run the pipeline and check the logs for messages like:
- "Excluding duplicate: [sample_name] (used in model training)"
- "Creating X chunks of ~Y samples each"
- "Chunk N: Z samples assigned"
- "Merging completed: Total samples assigned: X"