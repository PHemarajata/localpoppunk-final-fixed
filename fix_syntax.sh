#!/bin/bash

echo "Fixing syntax error at line 602..."

# Backup the original file
cp poppunk_subsample_snp.nf poppunk_subsample_snp.nf.backup_602

# Fix the specific problematic lines around line 602
sed -i 's/for pkl_file in poppunk_db_refined/        for pkl_file in poppunk_db_refined/g' poppunk_subsample_snp.nf
sed -i 's/for npz_file in poppunk_db_refined/        for npz_file in poppunk_db_refined/g' poppunk_subsample_snp.nf
sed -i 's/if \[ -f "$pkl_file" \]/            if [ -f "\\$pkl_file" ]/g' poppunk_subsample_snp.nf
sed -i 's/if \[ -f "$npz_file" \]/            if [ -f "\\$npz_file" ]/g' poppunk_subsample_snp.nf
sed -i 's/cp "$pkl_file"/                cp "\\$pkl_file"/g' poppunk_subsample_snp.nf
sed -i 's/cp "$npz_file"/                cp "\\$npz_file"/g' poppunk_subsample_snp.nf
sed -i 's/echo "✓ Created poppunk_db_refined_fit.pkl from $(basename "$pkl_file")"/                echo "✓ Created poppunk_db_refined_fit.pkl from \\$(basename "\\$pkl_file")"/g' poppunk_subsample_snp.nf
sed -i 's/echo "✓ Created poppunk_db_refined_fit.npz from $(basename "$npz_file")"/                echo "✓ Created poppunk_db_refined_fit.npz from \\$(basename "\\$npz_file")"/g' poppunk_subsample_snp.nf
sed -i 's/break/                break/g' poppunk_subsample_snp.nf
sed -i 's/done/        done/g' poppunk_subsample_snp.nf

echo "Syntax error fixed. Original file backed up as poppunk_subsample_snp.nf.backup_602"
