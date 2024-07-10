#!/bin/bash
# Array to store file paths
files=()

# Find all files matching the pattern
shopt -s nullglob
#for file in fasta_seq_files/*; do for all groups in one file

for file in groups_fasta/*; do
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
# Perform multiple sequence alignment using Clustal Omega
#"aligned_seq_files/$selection.fasta" /for all groups together
aligned_file="aligned_groups_files/clustal_$selection.fasta"

#clustalo -i "$fasta_file" -o "$aligned_file" --outfmt=fasta --force
clustalo -i "$input_file" -o "$aligned_file" -v --force
# Remove gaps from the Clustal alignment
#awk '/^clustalo/ {print; getline; print; next} {gsub(/-/,"",$NF); print}' "$fasta_file" > "$aligned_file" -v --force
#echo "Gaps removed from the alignment. Output saved to: $aligned_file"

# Output the aligned sequences
#cat "$aligned_file"
#jalview -open $aligned_file  -colour CLUSTAL  -out your_output_file.png

# Clean up temporary directory
#rm -r "$temp_dir"
