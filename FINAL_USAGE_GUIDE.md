# PopPUNK Pipeline with Model Refinement - Final Usage Guide

## 🎯 **Complete Implementation Ready**

Your PopPUNK pipeline now includes **model refinement** specifically optimized for B. pseudomallei's high recombination characteristics. This guide provides everything you need to run the enhanced pipeline.

## 🚀 **Quick Start Commands**

### **For 3,500 B. pseudomallei genomes (Recommended):**
```bash
nextflow run poppunk_subsample_snp.nf -profile large_dataset_optimized
```

### **If you encounter bus errors:**
```bash
nextflow run poppunk_subsample_snp.nf -profile bus_error_prevention
```

### **For maximum stability (no refinement):**
```bash
nextflow run poppunk_subsample_snp.nf -profile ultra_bus_error_prevention
```

## 📊 **Enhanced Pipeline Workflow**

```
1. FASTA Validation
   ├── Validates 3,500 input genomes
   └── Filters out problematic files

2. MASH Distance Calculation (if subsampling enabled)
   ├── Sketches all genomes
   └── Calculates pairwise distances

3. Intelligent Subsampling/All Samples
   ├── Graph-based representative selection
   └── Or uses all samples for modeling

4. PopPUNK Model Fitting
   ├── Enhanced parameters for B. pseudomallei
   ├── Progressive fallback strategy
   └── Bus error prevention

5. 🆕 PopPUNK Model Refinement
   ├── Accounts for recombination events
   ├── Improves cluster boundaries
   └── Better lineage separation

6. Sample Assignment (Chunked)
   ├── Uses refined model
   ├── Processes in memory-efficient chunks
   └── Prevents duplicate assignments

7. Results Merging & Reporting
   ├── Combines all chunk results
   └── Generates comprehensive summary
```

## 🔬 **Model Refinement Benefits**

### **Why Refinement Matters for B. pseudomallei:**
- **High recombination rate** requires refined cluster boundaries
- **Better separation** of true lineages vs. recombinant variants
- **More accurate epidemiological clustering**
- **Improved outbreak investigation capabilities**

### **What Refinement Does:**
- **Detects recombination events** in the genome
- **Adjusts cluster boundaries** to account for horizontal gene transfer
- **Improves accuracy** of phylogenetic relationships
- **Provides biologically meaningful** cluster assignments

## ⚙️ **Configuration Profiles Explained**

### **1. large_dataset_optimized** (Recommended)
```bash
# Best for: 3,500+ genomes, 22 cores, 64GB RAM
# Features: Full refinement, optimized parameters, enhanced clustering
nextflow run poppunk_subsample_snp.nf -profile large_dataset_optimized

# Key settings:
# - Refinement: ENABLED (both core and accessory)
# - Sketch size: 100,000 (high resolution)
# - K components: 4 (better separation)
# - Threading: Optimized for your hardware
```

### **2. bus_error_prevention** (Conservative)
```bash
# Best for: When experiencing stability issues
# Features: Refinement enabled, conservative resources
nextflow run poppunk_subsample_snp.nf -profile bus_error_prevention

# Key settings:
# - Refinement: ENABLED (conservative)
# - Sketch size: 100,000
# - K components: 4
# - Threading: Reduced for stability
```

### **3. ultra_bus_error_prevention** (Maximum Stability)
```bash
# Best for: When all else fails, need guaranteed completion
# Features: No refinement, minimal parameters
nextflow run poppunk_subsample_snp.nf -profile ultra_bus_error_prevention

# Key settings:
# - Refinement: DISABLED
# - Sketch size: 10,000 (minimal)
# - K components: 2
# - Threading: Single-threaded
```

## 📈 **Expected Results**

### **With Refinement (Recommended):**
- **Multiple meaningful clusters** (not single giant cluster)
- **Better lineage separation** for B. pseudomallei
- **More accurate epidemiological groupings**
- **Runtime**: 8-16 hours for 3,500 genomes

### **Without Refinement (Fallback):**
- **Basic clustering** (still functional)
- **May have some recombination artifacts**
- **Faster processing** but less biological accuracy
- **Runtime**: 6-12 hours for 3,500 genomes

## 🔍 **Monitoring Progress**

### **Key Success Messages:**
```bash
# Model fitting success:
✅ Model fitting completed with enhanced B. pseudomallei parameters

# Refinement success:
🔬 Starting PopPUNK model refinement for B. pseudomallei...
✅ Model refinement completed successfully
🎉 PopPUNK model refinement process completed!

# Assignment success:
✅ Chunk X assignment completed successfully
✅ PopPUNK assignment written: /path/to/results
```

### **Monitor Resource Usage:**
```bash
# In another terminal:
htop                    # Monitor CPU and memory
df -h                   # Monitor disk space
tail -f .nextflow.log   # Monitor pipeline progress
```

## 📁 **Output Files**

### **Main Results:**
```
results/
├── poppunk_full/
│   └── full_assign.csv              # Final cluster assignments
├── poppunk_model/
│   └── poppunk_db/                  # Original fitted model
├── poppunk_refined/
│   ├── poppunk_db_refined/          # Enhanced refined model
│   └── refinement_report.txt        # Refinement details
├── summary/
│   └── pipeline_summary.txt         # Overall results summary
└── validation/
    └── validation_report.txt        # Input validation results
```

### **Key Output File:**
- **`full_assign.csv`** - Contains sample names and cluster assignments
- **Format**: `sample,cluster`
- **Example**: `genome001,1`, `genome002,3`, etc.

## 🛠️ **Troubleshooting**

### **If Bus Errors Occur:**
1. **Switch profiles**: Try `bus_error_prevention` first
2. **Check resources**: Monitor memory usage with `htop`
3. **Reduce dataset**: Test with subset first
4. **Use ultra-conservative**: `ultra_bus_error_prevention` as last resort

### **If Refinement Fails:**
- **Pipeline continues** with original model
- **Check refinement report** for details
- **Results still valid** but may be less refined

### **If Memory Issues:**
```bash
# Check available memory
free -h

# Reduce chunk size (edit config)
--memory_per_chunk '16 GB'
--threads_per_chunk 4
```

## 🎯 **Custom Parameters**

### **Override Specific Settings:**
```bash
# Disable refinement for specific run
nextflow run poppunk_subsample_snp.nf \
  -profile large_dataset_optimized \
  --poppunk_enable_refinement false

# Use only core refinement
nextflow run poppunk_subsample_snp.nf \
  -profile large_dataset_optimized \
  --poppunk_refine_core_only true \
  --poppunk_refine_both false

# Adjust sketch size
nextflow run poppunk_subsample_snp.nf \
  -profile large_dataset_optimized \
  --poppunk_sketch_size 50000
```

## 📊 **Performance Expectations**

### **Hardware Requirements:**
- **Minimum**: 16 cores, 32GB RAM
- **Recommended**: 22 cores, 64GB RAM (your setup)
- **Optimal**: 32+ cores, 128GB RAM

### **Runtime Estimates (3,500 genomes):**
- **large_dataset_optimized**: 8-16 hours
- **bus_error_prevention**: 10-20 hours
- **ultra_bus_error_prevention**: 6-12 hours

### **Disk Space Requirements:**
- **Input**: ~10-20GB (3,500 FASTA files)
- **Working**: ~50-100GB (intermediate files)
- **Output**: ~5-10GB (final results)

## 🎉 **Success Criteria**

### **Pipeline Completed Successfully When:**
- ✅ **Multiple clusters identified** (not single giant cluster)
- ✅ **All 3,500 genomes processed** and assigned
- ✅ **Refinement completed** (if enabled)
- ✅ **Final CSV file generated** with cluster assignments
- ✅ **No bus errors or crashes**

### **Expected Cluster Distribution:**
- **10-50 clusters** for B. pseudomallei (typical range)
- **Largest cluster**: <50% of total genomes
- **Singleton clusters**: Some expected (unique strains)

## 🚀 **Ready to Run!**

Your enhanced PopPUNK pipeline with model refinement is ready for production use with your 3,500 B. pseudomallei genomes. The refinement feature will provide more accurate and biologically meaningful clustering results.

**Start with the recommended command and monitor progress!**

```bash
nextflow run poppunk_subsample_snp.nf -profile large_dataset_optimized
```