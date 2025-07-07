# PopPUNK Refinement Database Fix

## 🚨 **Issue Identified**

The pipeline was failing at the `POPPUNK_ASSIGN_CHUNK` step with the error:
```
FileNotFoundError: [Errno 2] Unable to synchronously open file (unable to open file: name = 'poppunk_db_refined/poppunk_db_refined.h5', errno = 2, error message = 'No such file or directory')
```

## 🔍 **Root Cause**

The POPPUNK_REFINE process was not properly copying all essential database files, particularly:
- **Missing `.h5` file**: Contains sketch data required for assignment
- **Incorrect file naming**: Refined database needs specific naming convention
- **Incomplete file verification**: Not checking for all critical files

## ✅ **Fix Applied**

### **Enhanced Database Integrity Verification**
Added comprehensive checks and copying for:

1. **Critical .h5 file**:
   ```bash
   # Copy original .h5 file with correct refined database name
   cp "${db_dir}/poppunk_db.h5" "poppunk_db_refined/poppunk_db_refined.h5"
   ```

2. **Additional database files**:
   ```bash
   # Copy all essential database components
   cp ${db_dir}/*.dists poppunk_db_refined/ 2>/dev/null
   cp ${db_dir}/*.refs poppunk_db_refined/ 2>/dev/null
   cp ${db_dir}/*.csv poppunk_db_refined/ 2>/dev/null
   ```

3. **Proper file naming**:
   ```bash
   # Ensure refined database has correctly named files
   cp "poppunk_db_refined/poppunk_db_fit.pkl" "poppunk_db_refined/poppunk_db_refined_fit.pkl"
   cp "poppunk_db_refined/poppunk_db_graph.gt" "poppunk_db_refined/poppunk_db_refined_graph.gt"
   ```

4. **Final verification**:
   ```bash
   # Check all critical files are present
   - poppunk_db_refined.h5 (sketch data)
   - fitted model (.pkl)
   - graph file (.gt)
   ```

## 🎯 **Expected Resolution**

After this fix:
- ✅ **Refined database will contain all necessary files**
- ✅ **Assignment step will find required .h5 file**
- ✅ **Pipeline will complete successfully**
- ✅ **Enhanced clustering with refinement benefits**

## 🚀 **Next Steps**

1. **Resume the pipeline**:
   ```bash
   nextflow run poppunk_subsample_snp.nf -profile large_dataset_optimized -resume
   ```

2. **Monitor refinement output**:
   - Look for "✅ Found critical file: poppunk_db_refined.h5"
   - Check "✅ All critical files present in refined database"

3. **Verify assignment success**:
   - Assignment should now complete without FileNotFoundError
   - Enhanced clustering results with refinement benefits

## 📊 **Benefits After Fix**

- **Complete database integrity** for refined model
- **Successful assignment** using refined clustering boundaries
- **Better B. pseudomallei clustering** with recombination handling
- **More accurate epidemiological results**

The fix ensures that the refined database contains all necessary components for successful PopPUNK assignment while maintaining the benefits of model refinement for B. pseudomallei.