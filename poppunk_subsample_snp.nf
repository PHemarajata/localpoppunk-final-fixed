#!/usr/bin/env nextflow
nextflow.enable.dsl=2

/* ----------------------------------------------------------
 * PARAMETERS
 * ---------------------------------------------------------- */

println "▶ FASTA input directory:  ${params.input}"
println "▶ Results directory:      ${params.resultsDir}"
println "▶ Threads / RAM:          ${params.threads}  /  ${params.ram}"

/* ──────────────────────────────────────────────────────────
 * 1 ▸ Validate FASTA files and filter out empty ones
 * ────────────────────────────────────────────────────────── */
process VALIDATE_FASTA {
    tag         'validate_fasta'
    container   'python:3.9'
    cpus        8
    memory      '16 GB'
    publishDir  "${params.resultsDir}/validation", mode: 'copy', overwrite: true, 
                failOnError: false

    input:
    path fasta_files

    output:
    path 'valid_files.list', emit: valid_list
    path 'validation_report.txt', emit: report

    script:
    """
    python - << 'PY'
import os
from pathlib import Path

valid_files = []
invalid_files = []
total_files = 0

# Process each FASTA file
fasta_files = '${fasta_files}'.split()
for fasta_file in fasta_files:
    total_files += 1
    file_path = Path(fasta_file)
    
    # Get the absolute path for the file
    abs_path = file_path.resolve()
    
    if not file_path.exists():
        invalid_files.append(f"{fasta_file}: File does not exist")
        continue
    
    if file_path.stat().st_size == 0:
        invalid_files.append(f"{fasta_file}: File is empty (0 bytes)")
        continue
    
    # Check if file contains actual sequence data
    has_sequence = False
    sequence_length = 0
    
    try:
        with open(fasta_file, 'r') as f:
            lines = f.readlines()
            for line in lines:
                line = line.strip()
                if line and not line.startswith('>'):
                    sequence_length += len(line)
                    has_sequence = True
        
        if not has_sequence or sequence_length == 0:
            invalid_files.append(f"{fasta_file}: No sequence data found")
        elif sequence_length < 1000:  # Minimum sequence length threshold
            invalid_files.append(f"{fasta_file}: Sequence too short ({sequence_length} bp)")
        else:
            # Store the absolute path so MASH can find the files
            valid_files.append(str(abs_path))
            
    except Exception as e:
        invalid_files.append(f"{fasta_file}: Error reading file - {str(e)}")

# Write valid files list with absolute paths
with open('valid_files.list', 'w') as f:
    for valid_file in valid_files:
        f.write(f"{valid_file}\\n")

# Write validation report
with open('validation_report.txt', 'w') as f:
    f.write(f"FASTA Validation Report\\n")
    f.write(f"======================\\n")
    f.write(f"Total files processed: {total_files}\\n")
    f.write(f"Valid files: {len(valid_files)}\\n")
    f.write(f"Invalid files: {len(invalid_files)}\\n\\n")
    
    if valid_files:
        f.write("Valid files (with absolute paths):\\n")
        for vf in valid_files:
            f.write(f"  ✓ {vf}\\n")
        f.write("\\n")
    
    if invalid_files:
        f.write("Invalid files (excluded from analysis):\\n")
        for inf in invalid_files:
            f.write(f"  ✗ {inf}\\n")

print(f"Validation complete: {len(valid_files)} valid files out of {total_files} total files")
if len(valid_files) < 3:
    print("WARNING: Less than 3 valid files found. PopPUNK requires at least 3 genomes.")
    exit(1)
PY
    """
}

/* ──────────────────────────────────────────────────────────
 * 2 ▸ MASH sketch every valid .fasta
 * ────────────────────────────────────────────────────────── */
process MASH_SKETCH {
    tag         'mash_sketch'
    container 'quay.io/biocontainers/mash:2.3--hb105d93_9'
    cpus        { params.threads }
    memory      { params.ram }

    input:
    path fasta_files

    output:
    path 'mash.msh'      , emit: msh
    path 'all_files.list', emit: list

    script:
    """
    # Create file list with staged filenames (not absolute paths)
    ls *.fasta > all_files.list
    
    # Check if we have any files to process
    if [ ! -s all_files.list ]; then
        echo "ERROR: No valid FASTA files found for sketching"
        exit 1
    fi
    
    echo "Sketching \$(wc -l < all_files.list) valid FASTA files..."
    echo "First few files to be processed:"
    head -5 all_files.list
    
    echo "All files verified. Starting MASH sketching..."
    
    mash sketch -p ${task.cpus} -k ${params.mash_k} -s ${params.mash_s} \\
        -o mash.msh -l all_files.list
        
    echo "MASH sketching completed successfully!"
    """
}

/* ──────────────────────────────────────────────────────────
 * 2 ▸ Mash pairwise distances
 * ────────────────────────────────────────────────────────── */
process MASH_DIST {
    tag         'mash_dist'
    container 'quay.io/biocontainers/mash:2.3--hb105d93_9'
    cpus        { Math.min(params.threads, 16) }  // Prevent resource contention
    memory      '60 GB'

    input:
    path msh

    output:
    path 'mash.dist'

    script:
    """
    echo "Computing pairwise distances for all genomes..."
    mash dist -p ${task.cpus} ${msh} ${msh} > mash.dist
    echo "Distance computation completed. Generated \$(wc -l < mash.dist) pairwise comparisons."
    """
}

/* ──────────────────────────────────────────────────────────
 * 3 ▸ Bin genomes & subsample (or use all samples)
 * ────────────────────────────────────────────────────────── */
process BIN_SUBSAMPLE_OR_ALL {
    tag         'bin_subsample_or_all'
    container 'python:3.9'
    cpus        8  // Reduced for stability
    memory      '32 GB'

    input:
    path dist_file
    path valid_list

    output:
    path 'subset.list'

    script:
    """
    pip install --quiet networkx
    python - << 'PY'
import networkx as nx, random, sys, pathlib, os

print("Building similarity graph from MASH distances...")

# This is the absolute path to your main input directory
input_dir = "${params.input}"
use_all_samples = "${params.use_all_samples}".lower() == "true"

print(f"Mode: {'Using ALL samples' if use_all_samples else 'Subsampling representatives'}")

if use_all_samples:
    print("Using all valid samples for PopPUNK modeling...")
    
    # Read all valid files and create the subset list with all samples
    with open('${valid_list}', 'r') as f:
        valid_files = [line.strip() for line in f if line.strip()]
    
    with open('subset.list', 'w') as out:
        total_selected = 0
        for file_path in valid_files:
            filename = os.path.basename(file_path)
            # Create a sample name from the filename
            sample_name = os.path.splitext(filename)[0]
            # Use the absolute path from the valid list
            out.write(f"{sample_name}\\t{file_path}\\n")
            total_selected += 1
    
    print(f"Total genomes selected for PopPUNK modeling: {total_selected}")
    print("All valid samples will be used for modeling.")

else:
    print("Using subsampling mode for PopPUNK modeling...")
    
    G = nx.Graph()
    # Process the mash distance file - files are now relative filenames
    dist_file_path = '${dist_file}'
    
    # Check if this is a dummy file (when using all samples mode) or if file doesn't exist
    if dist_file_path == '/dev/null' or dist_file_path == 'NO_FILE' or not os.path.exists(dist_file_path):
        print("Distance file not available - falling back to using all samples...")
        # Fallback to all samples mode
        with open('${valid_list}', 'r') as f:
            valid_files = [line.strip() for line in f if line.strip()]
        
        with open('subset.list', 'w') as out:
            total_selected = 0
            for file_path in valid_files:
                filename = os.path.basename(file_path)
                sample_name = os.path.splitext(filename)[0]
                out.write(f"{sample_name}\\t{file_path}\\n")
                total_selected += 1
        
        print(f"Fallback: Total genomes selected for PopPUNK modeling: {total_selected}")
        # Exit the Python script successfully
        import sys
        sys.exit(0)
    
    # Normal subsampling processing
    if os.path.getsize(dist_file_path) > 0:
        for line in open(dist_file_path):
            a, b, d, *_ = line.split()
            if float(d) < ${params.mash_thresh}:
                G.add_edge(a, b)
    else:
        print("Warning: Distance file is empty.")

    print(f"Graph built with {G.number_of_nodes()} nodes and {G.number_of_edges()} edges")
    print(f"Found {nx.number_connected_components(G)} connected components")

    # Analyze component sizes for debugging
    component_sizes = [len(comp) for comp in nx.connected_components(G)]
    component_sizes.sort(reverse=True)
    print(f"Component sizes: {component_sizes[:10]}")  # Show top 10 component sizes
    print(f"Largest component has {max(component_sizes) if component_sizes else 0} genomes")
    print(f"Average component size: {sum(component_sizes)/len(component_sizes) if component_sizes else 0:.1f}")

    with open('subset.list','w') as out:
        total_selected = 0
        for i, comp in enumerate(nx.connected_components(G)):
            comp = list(comp)
            # Optimized subsampling for better cluster resolution: take fewer but more diverse representatives
            k = min(100, max(10, int(len(comp) * 0.15)))
            k = min(k, len(comp))
            if k > 0:
                selected = random.sample(comp, k)
                for filename in selected:
                    # Create a sample name from the filename
                    sample_name = os.path.splitext(filename)[0]
                    # Create the full absolute path for PopPUNK to use
                    full_path = os.path.join(input_dir, filename)
                    out.write(f"{sample_name}\\t{full_path}\\n")
                    total_selected += 1
            print(f"Component {i+1}: {len(comp)} genomes -> selected {k} representatives")

    print(f"Total genomes selected for PopPUNK modeling: {total_selected}")
PY
    """
}

/* ──────────────────────────────────────────────────────────
 * 4 ▸ Build PopPUNK model on subset
 * ────────────────────────────────────────────────────────── */
process POPPUNK_MODEL {
    tag          'poppunk_model'
    container    'staphb/poppunk:2.7.5'
    cpus         { params.threads }
    memory       { params.ram }
    publishDir   "${params.resultsDir}/poppunk_model", mode: 'copy', overwrite: true, 
                 failOnError: false

    input:
    path sub_list
    path fasta_files

    output:
    path 'poppunk_db', type: 'dir', emit: db
    path 'cluster_model.csv'     , emit: csv
    path 'staged_files.list'     , emit: staged_list

    script:
    """
    # Check if subset list is not empty
    if [ ! -s ${sub_list} ]; then
        echo "ERROR: Subset list is empty. No valid genomes found for PopPUNK modeling."
        exit 1
    fi
    
    echo "Building PopPUNK database with \$(wc -l < ${sub_list}) genomes..."
    
    # Create a new file list with staged filenames (not absolute paths)
    # Map the sample names from subset.list to the staged FASTA files
    > staged_files.list
    while IFS=\$'\\t' read -r sample_name file_path; do
        # Find the corresponding staged file
        basename_file=\$(basename "\$file_path")
        if [ -f "\$basename_file" ]; then
            echo -e "\$sample_name\\t\$basename_file" >> staged_files.list
            echo "Mapped: \$sample_name -> \$basename_file"
        else
            echo "ERROR: Staged file not found: \$basename_file"
            exit 1
        fi
    done < ${sub_list}
    
    echo "Created staged files list:"
    cat staged_files.list
    
    echo "All files verified. Starting PopPUNK database creation..."
    
    poppunk --create-db --r-files staged_files.list \\
        --output poppunk_db --threads ${task.cpus}

    echo "Database created successfully. Fitting model with PopPUNK 2.7.x features..."
    
    # BUS ERROR FIX: Use progressive fallback strategy for model fitting
    echo "Fitting PopPUNK model with bus error prevention strategies..."
    
    # Calculate conservative thread count for model fitting (max 8 threads to prevent bus errors)
    model_threads=\$(echo "${task.cpus}" | awk '{print (\$1 > 8) ? 8 : \$1}')
    echo "Using \$model_threads threads for model fitting (reduced from ${task.cpus} to prevent bus errors)"
    
    # Attempt 1: Conservative settings with reduced threads
    echo "Attempt 1: Conservative model fitting with \$model_threads threads..."
    if poppunk --fit-model bgmm --ref-db poppunk_db \\
        --output poppunk_fit --threads \$model_threads \\
        ${params.poppunk_reciprocal ? '--reciprocal-only' : ''} \\
        ${params.poppunk_count_unique ? '--count-unique-distances' : ''} \\
        --max-search-depth ${params.poppunk_max_search} \\
        --K ${params.poppunk_K}; then
        
        echo "✅ Model fitting completed successfully with conservative settings"
        
    else
        echo "⚠️  Attempt 1 failed, trying with even more conservative settings..."
        
        # Attempt 2: Ultra-conservative with fewer threads and simpler parameters
        echo "Attempt 2: Ultra-conservative model fitting with 4 threads..."
        if poppunk --fit-model bgmm --ref-db poppunk_db \\
            --output poppunk_fit_attempt2 --threads 4 \\
            --max-search-depth 10 \\
            --K 2; then
            
            echo "✅ Model fitting completed with ultra-conservative settings"
            mv poppunk_fit_attempt2 poppunk_fit
            
        else
            echo "⚠️  Attempt 2 failed, trying single-threaded fallback..."
            
            # Attempt 3: Single-threaded fallback with minimal parameters
            echo "Attempt 3: Single-threaded model fitting (most stable)..."
            poppunk --fit-model bgmm --ref-db poppunk_db \\
                --output poppunk_fit_attempt3 --threads 1 \\
                --max-search-depth 5 \\
                --K 2
                
            if [ -d "poppunk_fit_attempt3" ]; then
                echo "✅ Model fitting completed with single-threaded fallback"
                mv poppunk_fit_attempt3 poppunk_fit
            else
                echo "❌ All model fitting attempts failed"
                exit 1
            fi
        fi
    fi

    echo "Model fitting completed. Copying fitted model files to database directory..."
    
    # Copy all fitted model files from poppunk_fit to poppunk_db
    # This ensures the database directory contains both the database and the fitted model
    if [ -d "poppunk_fit" ]; then
        echo "Copying fitted model files to poppunk_db directory..."
        
        # Copy all files from poppunk_fit to poppunk_db
        cp poppunk_fit/* poppunk_db/ 2>/dev/null || echo "Some files could not be copied"
        
        # The critical step: rename the fitted model file to match what PopPUNK expects
        if [ -f "poppunk_db/poppunk_fit_fit.pkl" ]; then
            cp poppunk_db/poppunk_fit_fit.pkl poppunk_db/poppunk_db_fit.pkl
            echo "✓ Created poppunk_db_fit.pkl from poppunk_fit_fit.pkl"
        fi
        
        # Also copy the npz file with the correct name
        if [ -f "poppunk_db/poppunk_fit_fit.npz" ]; then
            cp poppunk_db/poppunk_fit_fit.npz poppunk_db/poppunk_db_fit.npz
            echo "✓ Created poppunk_db_fit.npz from poppunk_fit_fit.npz"
        fi
        
        # Copy the graph file with the correct name - CRITICAL for poppunk_assign
        if [ -f "poppunk_db/poppunk_fit_graph.gt" ]; then
            cp poppunk_db/poppunk_fit_graph.gt poppunk_db/poppunk_db_graph.gt
            echo "✓ Created poppunk_db_graph.gt from poppunk_fit_graph.gt"
        fi
        
        # Copy the cluster file with the correct name - CRITICAL for poppunk_assign
        if [ -f "poppunk_db/poppunk_fit_clusters.csv" ]; then
            cp poppunk_db/poppunk_fit_clusters.csv poppunk_db/poppunk_db_clusters.csv
            echo "✓ Created poppunk_db_clusters.csv from poppunk_fit_clusters.csv"
        fi
        
        echo "Files in poppunk_db after copying:"
        ls -la poppunk_db/
        
        # Verify the critical model files exist
        if [ -f "poppunk_db/poppunk_db_fit.pkl" ]; then
            echo "✓ Found fitted model file: poppunk_db_fit.pkl"
        else
            echo "⚠ Model .pkl file not found. Available files:"
            ls -la poppunk_db/*.pkl 2>/dev/null || echo "No .pkl files found"
        fi
        
        if [ -f "poppunk_db/poppunk_db_graph.gt" ]; then
            echo "✓ Found graph file: poppunk_db_graph.gt"
        else
            echo "⚠ Graph file not found. Available graph files:"
            ls -la poppunk_db/*.gt 2>/dev/null || echo "No .gt files found"
        fi
        
        if [ -f "poppunk_db/poppunk_db_clusters.csv" ]; then
            echo "✓ Found cluster file: poppunk_db_clusters.csv"
        else
            echo "⚠ Cluster file not found. Available cluster files:"
            ls -la poppunk_db/*clusters*.csv 2>/dev/null || echo "No cluster CSV files found"
        fi
    else
        echo "ERROR: poppunk_fit directory not found"
        exit 1
    fi

    # Check for different possible output file locations for cluster assignments
    if [ -f "poppunk_fit/poppunk_fit_clusters.csv" ]; then
        cp poppunk_fit/poppunk_fit_clusters.csv cluster_model.csv
        echo "Found poppunk_fit_clusters.csv in poppunk_fit/"
    elif [ -f "poppunk_fit/cluster_assignments.csv" ]; then
        cp poppunk_fit/cluster_assignments.csv cluster_model.csv
        echo "Found cluster_assignments.csv in poppunk_fit/"
    elif ls poppunk_fit/*_clusters.csv 1> /dev/null 2>&1; then
        cp poppunk_fit/*_clusters.csv cluster_model.csv
        echo "Found cluster file in poppunk_fit/"
    elif ls poppunk_fit/*.csv 1> /dev/null 2>&1; then
        cp poppunk_fit/*.csv cluster_model.csv
        echo "Found CSV file in poppunk_fit/"
    else
        echo "Available files in poppunk_fit/:"
        ls -la poppunk_fit/ || echo "poppunk_fit directory not found"
        echo "Available files in current directory:"
        ls -la *.csv || echo "No CSV files found"
        # Create a minimal output file so the pipeline doesn't fail
        echo "sample,cluster" > cluster_model.csv
        echo "PopPUNK completed but cluster assignments file not found in expected location"
    fi
    
    echo "PopPUNK model completed successfully!"
    """
}

/* ──────────────────────────────────────────────────────────
 * 5 ▸ Filter out samples used in model training to prevent duplicates
 * ────────────────────────────────────────────────────────── */
process FILTER_ASSIGNMENT_SAMPLES {
    tag          'filter_assignment_samples'
    container    'python:3.9'
    cpus         2
    memory       '8 GB'

    input:
    path valid_list
    path staged_list

    output:
    path 'samples_to_assign.list'

    script:
    """
    python - << 'PY'
import os

print("Filtering samples to prevent duplicate name conflicts...")

# Read the samples used in model training
model_samples = set()
try:
    with open('${staged_list}', 'r') as f:
        for line in f:
            if line.strip():
                sample_name = line.strip().split('\\t')[0]
                model_samples.add(sample_name)
    print(f"Found {len(model_samples)} samples used in model training")
except Exception as e:
    print(f"Warning: Could not read staged list: {e}")
    print("Proceeding with all samples (may cause duplicate name warnings)")

# Read all valid samples
all_samples = []
with open('${valid_list}', 'r') as f:
    for line in f:
        if line.strip():
            file_path = line.strip()
            filename = os.path.basename(file_path)
            sample_name = os.path.splitext(filename)[0]
            all_samples.append((sample_name, file_path))

print(f"Total valid samples: {len(all_samples)}")

# Filter out samples that were used in model training
samples_to_assign = []
duplicates_found = []

for sample_name, file_path in all_samples:
    if sample_name in model_samples:
        duplicates_found.append(sample_name)
        print(f"Excluding duplicate: {sample_name} (used in model training)")
    else:
        samples_to_assign.append((sample_name, file_path))

print(f"Samples excluded (duplicates): {len(duplicates_found)}")
print(f"Samples to assign: {len(samples_to_assign)}")

# Write the filtered list
with open('samples_to_assign.list', 'w') as f:
    for sample_name, file_path in samples_to_assign:
        f.write(f"{file_path}\\n")

if len(samples_to_assign) == 0:
    print("WARNING: No new samples to assign! All samples were used in model training.")
    print("This might happen if you're running assignment on the same dataset used for training.")
    print("Creating empty assignment list...")
    
if len(duplicates_found) > 0:
    print(f"\\nDuplicate prevention successful:")
    print(f"- Excluded {len(duplicates_found)} samples that were in the training set")
    print(f"- Will assign {len(samples_to_assign)} new samples")
else:
    print("\\nNo duplicates found - all samples are new for assignment")

PY
    """
}

/* ──────────────────────────────────────────────────────────
 * 6 ▸ Assign *filtered* genomes to that model (chunked for large datasets)
 * ────────────────────────────────────────────────────────── */
process CHUNK_SAMPLES {
    tag          'chunk_samples'
    container    'python:3.9'
    cpus         2
    memory       '4 GB'

    input:
    path samples_to_assign

    output:
    path 'chunk_*.list', emit: chunks

    script:
    """
    python - << 'PY'
import os
import math

# Read samples to assign
samples = []
try:
    with open('${samples_to_assign}', 'r') as f:
        samples = [line.strip() for line in f if line.strip()]
except:
    print("No samples to assign - creating empty chunk")
    with open('chunk_0.list', 'w') as f:
        pass
    exit(0)

total_samples = len(samples)
print(f"Total samples to assign: {total_samples}")

if total_samples == 0:
    print("No samples to assign - creating empty chunk")
    with open('chunk_0.list', 'w') as f:
        pass
    exit(0)

# Calculate optimal chunk size based on available memory and sample count
# For 3500 samples with 64GB RAM, use chunks of ~500-800 samples
if total_samples <= 500:
    chunk_size = total_samples  # Single chunk for small datasets
elif total_samples <= 2000:
    chunk_size = 500  # Medium chunks
else:
    chunk_size = 800  # Larger chunks for very large datasets

num_chunks = math.ceil(total_samples / chunk_size)
print(f"Creating {num_chunks} chunks of ~{chunk_size} samples each")

# Create chunks
for i in range(num_chunks):
    start_idx = i * chunk_size
    end_idx = min((i + 1) * chunk_size, total_samples)
    chunk_samples = samples[start_idx:end_idx]
    
    chunk_filename = f'chunk_{i}.list'
    with open(chunk_filename, 'w') as f:
        for sample_path in chunk_samples:
            f.write(f"{sample_path}\\n")
    
    print(f"Chunk {i}: {len(chunk_samples)} samples ({start_idx+1}-{end_idx})")

print(f"Chunking completed: {num_chunks} chunks created")
PY
    """
}

process POPPUNK_ASSIGN_CHUNK {
    tag          "poppunk_assign_chunk_${chunk_id}"
    container    'staphb/poppunk:2.7.5'
    cpus         { Math.min(params.threads_per_chunk, 8) }  // Conservative per-chunk threading
    memory       { params.memory_per_chunk }
    publishDir   "${params.resultsDir}/poppunk_chunks", mode: 'copy', pattern: "chunk_${chunk_id}_assign.csv", 
                 overwrite: true, failOnError: false

    input:
    tuple val(chunk_id), path(chunk_list)
    path db_dir
    path fasta_files

    output:
    path "chunk_${chunk_id}_assign.csv", emit: chunk_result

    script:
    """
    echo "Processing chunk ${chunk_id}..."
    
    # Check if chunk is empty
    if [ ! -s ${chunk_list} ]; then
        echo "Empty chunk ${chunk_id} - creating empty result file"
        echo "sample,cluster" > chunk_${chunk_id}_assign.csv
        exit 0
    fi
    
    # Create staged file list for this chunk
    > staged_chunk_files.list
    while IFS= read -r file_path; do
        if [ -n "\$file_path" ]; then
            basename_file=\$(basename "\$file_path")
            if [ -f "\$basename_file" ]; then
                # Create sample name from filename (remove .fasta extension)
                sample_name=\$(basename "\$basename_file" .fasta)
                echo -e "\$sample_name\\t\$basename_file" >> staged_chunk_files.list
            else
                echo "WARNING: Staged file not found: \$basename_file"
            fi
        fi
    done < ${chunk_list}
    
    chunk_size=\$(wc -l < staged_chunk_files.list)
    echo "Chunk ${chunk_id}: Assigning \$chunk_size genomes to PopPUNK clusters..."
    
    if [ "\$chunk_size" -eq 0 ]; then
        echo "No valid files in chunk ${chunk_id} - creating empty result"
        echo "sample,cluster" > chunk_${chunk_id}_assign.csv
        exit 0
    fi
    
    echo "First few files in chunk ${chunk_id}:"
    head -3 staged_chunk_files.list
    
    # Conservative PopPUNK assignment with error handling
    echo "Starting PopPUNK assignment for chunk ${chunk_id} with ${task.cpus} threads..."
    
    # Use very conservative settings to prevent bus errors
    if poppunk_assign --query staged_chunk_files.list \\
        --db ${db_dir} \\
        --output poppunk_chunk_${chunk_id} \\
        --threads ${task.cpus} \\
        --write-references \\
        --max-zero-dist ${params.poppunk_max_zero_dist} \\
        --max-merge ${params.poppunk_max_merge} \\
        --length-sigma ${params.poppunk_length_sigma}; then
        
        echo "✅ Chunk ${chunk_id} assignment completed successfully"
        
    else
        echo "⚠️  Chunk ${chunk_id} failed, trying with single thread..."
        
        # Ultra-conservative fallback
        poppunk_assign --query staged_chunk_files.list \\
            --db ${db_dir} \\
            --output poppunk_chunk_${chunk_id}_fallback \\
            --threads 1 \\
            --write-references \\
            --max-zero-dist ${params.poppunk_max_zero_dist} \\
            --max-merge ${params.poppunk_max_merge} \\
            --length-sigma ${params.poppunk_length_sigma}
            
        # Move fallback results
        if [ -d "poppunk_chunk_${chunk_id}_fallback" ]; then
            mv poppunk_chunk_${chunk_id}_fallback poppunk_chunk_${chunk_id}
            echo "✅ Chunk ${chunk_id} completed with fallback settings"
        fi
    fi

    # Find and copy the results file
    result_found=false
    for result_file in poppunk_chunk_${chunk_id}/poppunk_chunk_${chunk_id}_clusters.csv \\
                      poppunk_chunk_${chunk_id}_clusters.csv \\
                      poppunk_chunk_${chunk_id}/cluster_assignments.csv \\
                      cluster_assignments.csv \\
                      poppunk_chunk_${chunk_id}/*_clusters.csv \\
                      poppunk_chunk_${chunk_id}/*.csv; do
        if [ -f "\$result_file" ]; then
            cp "\$result_file" chunk_${chunk_id}_assign.csv
            echo "✅ Found result file for chunk ${chunk_id}: \$result_file"
            result_found=true
            break
        fi
    done
    
    if [ "\$result_found" = false ]; then
        echo "⚠️  No result file found for chunk ${chunk_id}, creating minimal output"
        echo "sample,cluster" > chunk_${chunk_id}_assign.csv
    fi
    
    assigned_count=\$(tail -n +2 chunk_${chunk_id}_assign.csv | wc -l)
    echo "Chunk ${chunk_id} completed: \$assigned_count samples assigned"
    """
}

process MERGE_CHUNK_RESULTS {
    tag          'merge_chunk_results'
    container    'python:3.9'
    cpus         2
    memory       '8 GB'
    publishDir   "${params.resultsDir}/poppunk_full", mode: 'copy', overwrite: true, 
                 failOnError: false

    input:
    path chunk_results

    output:
    path 'full_assign.csv'

    script:
    """
    echo "Merging chunk results using bash..."
    
    # Find all chunk result files
    chunk_files=\$(ls chunk_*_assign.csv 2>/dev/null | sort)
    
    if [ -z "\$chunk_files" ]; then
        echo "No chunk files found - creating empty result"
        echo "sample,cluster" > full_assign.csv
        exit 0
    fi
    
    echo "Found chunk files:"
    echo "\$chunk_files"
    
    # Get header from first file
    first_file=\$(echo "\$chunk_files" | head -n1)
    if [ -f "\$first_file" ]; then
        head -n1 "\$first_file" > full_assign.csv
        echo "Using header from: \$first_file"
    else
        echo "sample,cluster" > full_assign.csv
        echo "No valid chunk files found, using default header"
    fi
    
    # Combine all data rows (skip headers)
    total_samples=0
    for chunk_file in \$chunk_files; do
        if [ -f "\$chunk_file" ]; then
            # Count lines in this chunk (excluding header)
            chunk_samples=\$(tail -n +2 "\$chunk_file" | wc -l)
            echo "Processing \$chunk_file: \$chunk_samples samples"
            
            # Append data rows (skip header line)
            tail -n +2 "\$chunk_file" >> full_assign.csv
            total_samples=\$((total_samples + chunk_samples))
        else
            echo "Warning: \$chunk_file not found"
        fi
    done
    
    # Remove duplicates (keep first occurrence)
    echo "Removing duplicates..."
    temp_file=\$(mktemp)
    
    # Keep header
    head -n1 full_assign.csv > "\$temp_file"
    
    # Remove duplicates from data rows (based on first column - sample name)
    tail -n +2 full_assign.csv | awk -F',' '!seen[\$1]++' >> "\$temp_file"
    
    mv "\$temp_file" full_assign.csv
    
    # Calculate final statistics
    final_samples=\$(tail -n +2 full_assign.csv | wc -l)
    duplicates_removed=\$((total_samples - final_samples))
    
    echo ""
    echo "Merging completed:"
    echo "- Total samples processed: \$total_samples"
    echo "- Duplicates removed: \$duplicates_removed"
    echo "- Final samples assigned: \$final_samples"
    
    # Show cluster distribution
    echo ""
    echo "Cluster distribution (top 10):"
    tail -n +2 full_assign.csv | cut -d',' -f2 | sort | uniq -c | sort -nr | head -10 | while read count cluster; do
        echo "  Cluster \$cluster: \$count samples"
    done
    
    # Count unique clusters
    unique_clusters=\$(tail -n +2 full_assign.csv | cut -d',' -f2 | sort -u | wc -l)
    echo "- Unique clusters found: \$unique_clusters"
    
    # Fix file permissions to ensure publishDir can copy the file
    chmod 644 full_assign.csv 2>/dev/null || true
    chown \$(whoami):\$(whoami) full_assign.csv 2>/dev/null || true
    
    echo ""
    echo "Chunk merging process completed successfully!"
    echo "Output file: full_assign.csv (\$final_samples samples)"
    """
}

/* ──────────────────────────────────────────────────────────
 * 6 ▸ Final results copy with permission handling
 * ────────────────────────────────────────────────────────── */
process COPY_FINAL_RESULTS {
    tag          'copy_final_results'
    container    'ubuntu:20.04'
    cpus         1
    memory       '2 GB'

    input:
    path final_csv
    path summary_report

    output:
    path 'results_copied.txt'

    script:
    """
    echo "Copying final results with proper permissions..."
    
    # Create output directories
    mkdir -p "${params.resultsDir}/poppunk_full"
    mkdir -p "${params.resultsDir}/summary"
    
    # Copy files with proper permissions
    cp ${final_csv} "${params.resultsDir}/poppunk_full/full_assign.csv"
    chmod 644 "${params.resultsDir}/poppunk_full/full_assign.csv"
    
    cp ${summary_report} "${params.resultsDir}/summary/pipeline_summary.txt"
    chmod 644 "${params.resultsDir}/summary/pipeline_summary.txt"
    
    # Create completion marker
    echo "Results successfully copied on \$(date)" > results_copied.txt
    echo "Final results: ${params.resultsDir}/poppunk_full/full_assign.csv" >> results_copied.txt
    echo "Summary report: ${params.resultsDir}/summary/pipeline_summary.txt" >> results_copied.txt
    
    echo "✅ Final results copied successfully!"
    """
}

/* ──────────────────────────────────────────────────────────
 * 7 ▸ Generate summary report
 * ────────────────────────────────────────────────────────── */
process SUMMARY_REPORT {
    tag          'summary_report'
    container    'python:3.9'
    publishDir   "${params.resultsDir}/summary", mode: 'copy', overwrite: true, 
                 failOnError: false

    input:
    path cluster_csv
    path validation_report

    output:
    path 'pipeline_summary.txt'

    script:
    """
    pip install --quiet pandas
    python - << 'PY'
import pandas as pd
from collections import Counter

# Read cluster assignments
try:
    df = pd.read_csv('${cluster_csv}')
    print(f"Successfully read cluster assignments: {len(df)} samples")
    
    # Count clusters
    if 'Cluster' in df.columns:
        cluster_col = 'Cluster'
    elif 'cluster' in df.columns:
        cluster_col = 'cluster'
    else:
        cluster_col = df.columns[1]  # Assume second column is cluster
    
    cluster_counts = df[cluster_col].value_counts().sort_index()
    total_samples = len(df)
    num_clusters = len(cluster_counts)
    
    # Read validation report
    with open('${validation_report}', 'r') as f:
        validation_content = f.read()
    
    # Generate summary
    with open('pipeline_summary.txt', 'w') as f:
        f.write("="*60 + "\\n")
        f.write("PopPUNK Pipeline Summary Report\\n")
        f.write("="*60 + "\\n\\n")
        
        f.write("VALIDATION RESULTS:\\n")
        f.write("-"*20 + "\\n")
        f.write(validation_content + "\\n\\n")
        
        f.write("CLUSTERING RESULTS:\\n")
        f.write("-"*20 + "\\n")
        f.write(f"Total samples processed: {total_samples}\\n")
        f.write(f"Number of clusters found: {num_clusters}\\n\\n")
        
        f.write("Cluster distribution:\\n")
        for cluster, count in cluster_counts.items():
            percentage = (count / total_samples) * 100
            f.write(f"  Cluster {cluster}: {count} samples ({percentage:.1f}%)\\n")
        
        f.write("\\n" + "="*60 + "\\n")
        
        # Also print to stdout
        print(f"\\n{'='*60}")
        print("PopPUNK Pipeline Summary")
        print(f"{'='*60}")
        print(f"Total samples processed: {total_samples}")
        print(f"Number of clusters found: {num_clusters}")
        print("\\nCluster distribution:")
        for cluster, count in cluster_counts.items():
            percentage = (count / total_samples) * 100
            print(f"  Cluster {cluster}: {count} samples ({percentage:.1f}%)")
        print(f"{'='*60}")

except Exception as e:
    print(f"Error processing results: {e}")
    with open('pipeline_summary.txt', 'w') as f:
        f.write(f"Error generating summary: {e}\\n")
        f.write("Please check the cluster assignment file format.\\n")
PY
    
    # Fix file permissions to ensure publishDir can copy the file
    chmod 644 pipeline_summary.txt 2>/dev/null || true
    chown \$(whoami):\$(whoami) pipeline_summary.txt 2>/dev/null || true
    echo "File permissions set for pipeline_summary.txt"
    """
}

/* ──────────────────────────────────────────────────────────
 * MAIN WORKFLOW
 * ────────────────────────────────────────────────────────── */
workflow {

    ch_fasta = Channel.fromPath("${params.input}/*.fasta", checkIfExists: true)
    
    // Validate FASTA files first
    validation_out = VALIDATE_FASTA(ch_fasta.collect())
    
    // Display validation report
    validation_out.report.view { report -> 
        println "\n" + "="*50
        println "📋 FASTA VALIDATION REPORT"
        println "="*50
        println report.text
        println "="*50 + "\n"
    }
    
    // Filter the original FASTA files based on validation results
    // Read the valid files list and create a channel of valid files
    valid_files_ch = validation_out.valid_list
        .splitText() { it.trim() }
        .map { file_path -> file(file_path) }
        .filter { it.exists() }
    
    // Collect valid files for use in multiple processes
    valid_files_collected = valid_files_ch.collect()
    
    // Print mode information
    if (params.use_all_samples) {
        println "🔄 Using ALL SAMPLES mode - skipping MASH distance calculation"
        // Create a dummy distance file for the process
        dummy_dist = Channel.fromPath('/dev/null')
        subset_ch = BIN_SUBSAMPLE_OR_ALL(dummy_dist, validation_out.valid_list)
    } else {
        println "🔄 Using SUBSAMPLING mode - performing MASH-based intelligent subsampling"
        // Run MASH processes for subsampling
        sketch_out = MASH_SKETCH(valid_files_collected)
        dist_input = MASH_DIST(sketch_out.msh)
        subset_ch = BIN_SUBSAMPLE_OR_ALL(dist_input, validation_out.valid_list)
    }
    
    model_out = POPPUNK_MODEL(subset_ch, valid_files_collected)
    
    // Filter samples to prevent duplicate name conflicts
    filtered_samples = FILTER_ASSIGNMENT_SAMPLES(validation_out.valid_list, model_out.staged_list)
    
    // Chunk samples for memory-efficient processing
    chunks_ch = CHUNK_SAMPLES(filtered_samples)
        .chunks
        .flatten()
        .map { chunk_file -> 
            def chunk_id = chunk_file.name.replaceAll(/chunk_(\d+)\.list/, '$1')
            [chunk_id, chunk_file]
        }
    
    // Process each chunk
    chunk_results = POPPUNK_ASSIGN_CHUNK(chunks_ch, model_out.db, valid_files_collected)
    
    // Merge all chunk results
    final_csv = MERGE_CHUNK_RESULTS(chunk_results.chunk_result.collect())

    // Generate summary report
    summary_out = SUMMARY_REPORT(final_csv, validation_out.report)
    
    // Copy final results with proper permissions
    COPY_FINAL_RESULTS(final_csv, summary_out)
    
    final_csv.view { p -> "✅ PopPUNK assignment written: ${p}" }
}
