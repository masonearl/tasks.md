#!/bin/bash

# Script to add sample_tasks.md to the Xcode project

cd "/Users/masdawg/Desktop/Brain/Mason/1. Projects/3. Code/Tasks.md App/Tasks.md"

# Generate unique IDs for the project file
SAMPLE_FILE_REF_ID="SAMPLE$(uuidgen | tr -d '-' | cut -c1-24)"
BUILD_FILE_ID="BUILD$(uuidgen | tr -d '-' | cut -c1-24)"

PROJECT_FILE="Tasks.md.xcodeproj/project.pbxproj"

echo "Adding sample_tasks.md to Xcode project..."

# Backup the project file
cp "$PROJECT_FILE" "${PROJECT_FILE}.backup"

# Find the main group section and add file reference
# This is a simplified approach - in practice you'd want to parse the XML properly
echo "
/* sample_tasks.md */
$SAMPLE_FILE_REF_ID /* sample_tasks.md */ = {isa = PBXFileReference; lastKnownFileType = net.daringfireball.markdown; path = sample_tasks.md; sourceTree = \"<group>\"; };" >> /tmp/file_ref.txt

echo "✅ Sample file reference IDs generated"
echo "File Reference ID: $SAMPLE_FILE_REF_ID"
echo "Build File ID: $BUILD_FILE_ID"

echo ""
echo "📝 Manual Steps Required:"
echo "1. Open Tasks.md.xcodeproj in Xcode"
echo "2. Select the 'Tasks.md' folder (the one with ContentView.swift)"
echo "3. Right-click and select 'Add Files to \"Tasks.md\"...'"
echo "4. Navigate to and select 'sample_tasks.md'"
echo "5. ✅ CHECK 'Copy items if needed'"
echo "6. ✅ CHECK 'Add to targets: Tasks.md'"
echo "7. Click 'Add'"
echo ""
echo "The file will be automatically included in the app bundle!"

