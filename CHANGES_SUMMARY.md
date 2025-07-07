# Changes Summary: Added Option to Use All Samples

## Overview
Modified the PopPUNK pipeline to provide an option to include every sample for PopPUNK modeling instead of performing subsampling.

## Changes Made

### 1. New Parameter Added
- **File**: `nextflow.config`
- **Parameter**: `use_all_samples = false` (default)
- **Description**: Controls whether to use all samples or perform intelligent subsampling

### 2. Process Modification
- **Original**: `BIN_SUBSAMPLE` process
- **New**: `BIN_SUBSAMPLE_OR_ALL` process
- **Changes**:
  - Added logic to handle both sampling modes
  - When `use_all_samples = true`: Uses all validated samples directly
  - When `use_all_samples = false`: Performs original subsampling logic
  - Added input for `valid_list` to access all validated samples

### 3. Workflow Updates
- **File**: `poppunk_subsample_snp.nf`
- **Changes**:
  - Added conditional logic to skip MASH distance calculation when using all samples
  - Updated process calls to use new `BIN_SUBSAMPLE_OR_ALL` process
  - Optimized workflow to save computation time when not subsampling

### 4. Configuration File
- **New File**: `conf/use_all_samples.config`
- **Purpose**: Example configuration for using all samples mode
- **Features**: 
  - Sets `use_all_samples = true`
  - Includes recommended resource adjustments for processing all samples

### 5. Documentation Updates
- **File**: `README.md`
- **Added**:
  - New "Sampling Modes" section explaining both options
  - Usage examples for both modes
  - Guidance on when to use each mode
  - Updated feature list and parameter documentation

### 6. Test Script
- **New File**: `test_all_samples_mode.sh`
- **Purpose**: Test script to verify both sampling modes work correctly

## Usage

### Use All Samples (New Feature)
```bash
# Method 1: Using parameter
nextflow run poppunk_subsample_snp.nf --use_all_samples true

# Method 2: Using configuration file
nextflow run poppunk_subsample_snp.nf -c conf/use_all_samples.config
```

### Use Subsampling (Default Behavior)
```bash
# Default behavior (unchanged)
nextflow run poppunk_subsample_snp.nf

# Explicit parameter
nextflow run poppunk_subsample_snp.nf --use_all_samples false
```

## Benefits

### When Using All Samples (`use_all_samples = true`)
- **Maximum resolution**: Every sample included in PopPUNK modeling
- **No information loss**: All samples contribute to clustering
- **Faster preprocessing**: Skips MASH distance calculation
- **Ideal for**: Smaller datasets or when every sample is critical

### When Using Subsampling (`use_all_samples = false`, default)
- **Computational efficiency**: Reduced processing time and memory usage
- **Scalability**: Handles large datasets (>200 genomes) effectively
- **Maintained structure**: Preserves population structure through intelligent sampling
- **Ideal for**: Large datasets or resource-constrained environments

## Backward Compatibility
- All existing functionality preserved
- Default behavior unchanged (subsampling mode)
- Existing configurations and scripts continue to work without modification