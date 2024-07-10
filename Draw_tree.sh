#!/bin/bash
# Array to store file paths
files=()

# Find all files matching the pattern
shopt -s nullglob

for file in aligned_seq_files/*; do
    files+=("$file")
done

# Check if any files were found
if [ ${#files[@]} -eq 0 ]; then
    echo "No files found matching the pattern."
    exit 1
fi

# Display files to the user for selection
echo "Select a file:"
for ((i=0; i<${#files[@]}; i++)); do
    num_lines=$(wc -l < "${files[$i]}")
    echo "$i: ${files[$i]} ($num_lines rows)"
done

# Read user input for selection
read -p "Enter the number corresponding to the file: " selection

# Validate user input
if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 0 ] || [ "$selection" -ge ${#files[@]} ]; then
    echo "Invalid selection. Please enter a valid number."
    exit 1
fi

# Get the selected file path
input_file="${files[$selection]}"
num_lines=$(wc -l < "$input_file")

echo "we will fetch data with the query in index $input_file" 

tree_file="phy_tree/tree_$selection.newick"
fasttree -lg $input_file> $tree_file
