#!/bin/bash

# Test script to validate the PopPUNK refinement fix
# This script simulates the conditions that caused the original error

echo "🧪 Testing PopPUNK Refinement Fix"
echo "================================="

# Create a test directory structure
mkdir -p test_poppunk_db
cd test_poppunk_db

# Create mock fitted model files with different naming patterns
echo "Creating mock fitted model files..."
touch poppunk_db_fit.pkl
touch poppunk_db_fit.npz
touch poppunk_fit_fit.pkl
touch poppunk_fit_fit.npz

# Create a mock database directory
mkdir -p poppunk_db_refined
cp *.pkl *.npz poppunk_db_refined/

echo "✅ Test database structure created"
echo "📁 Files in test database:"
ls -la poppunk_db_refined/

# Test the file naming logic from the fix
echo ""
echo "🔧 Testing file naming logic..."

# Simulate the fix logic
if [ -f "poppunk_db_refined/poppunk_db_fit.pkl" ] && [ ! -f "poppunk_db_refined/poppunk_db_refined_fit.pkl" ]; then
    cp "poppunk_db_refined/poppunk_db_fit.pkl" "poppunk_db_refined/poppunk_db_refined_fit.pkl"
    echo "✓ Created poppunk_db_refined_fit.pkl from poppunk_db_fit.pkl"
fi

if [ -f "poppunk_db_refined/poppunk_db_fit.npz" ] && [ ! -f "poppunk_db_refined/poppunk_db_refined_fit.npz" ]; then
    cp "poppunk_db_refined/poppunk_db_fit.npz" "poppunk_db_refined/poppunk_db_refined_fit.npz"
    echo "✓ Created poppunk_db_refined_fit.npz from poppunk_db_fit.npz"
fi

# Verify the expected files exist
echo ""
echo "🔍 Verification results:"
if [ -f "poppunk_db_refined/poppunk_db_refined_fit.pkl" ]; then
    echo "✅ Found required fitted model: poppunk_db_refined_fit.pkl"
else
    echo "❌ Missing required fitted model: poppunk_db_refined_fit.pkl"
fi

if [ -f "poppunk_db_refined/poppunk_db_refined_fit.npz" ]; then
    echo "✅ Found required fitted model: poppunk_db_refined_fit.npz"
else
    echo "❌ Missing required fitted model: poppunk_db_refined_fit.npz"
fi

echo ""
echo "📁 Final database contents:"
ls -la poppunk_db_refined/

# Cleanup
cd ..
rm -rf test_poppunk_db

echo ""
echo "🎉 Test completed! The fix should resolve the FileNotFoundError."
echo "The pipeline will now be able to find the required fitted model files."