#!/bin/bash
# Array to store file paths
files=()

# Find all files matching the pattern
shopt -s nullglob

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
# Extract the file name from the file path
file_name=$(basename "$input_file" | cut -d '.' -f 1)
echo "Selected file name: $file_name"

echo "We will fetch data with the query in index $input_file" 


# Define input file (protein kinase sequences) and BLAST database (UniProt protein families)

blast_database="/media/elham/6437-3664/Project/uniprot_sprot.fasta"
makeblastdb -in uniprot_sprot.fasta -dbtype prot

# Perform BLAST searches for each protein kinase sequence
while read -r line; do
    if [[ "$line" == ">"* ]]; then
        # Extract sequence ID
        seq_id=$(echo "$line" | tr -d ">")
    else
        # Perform BLAST search for the sequence
        echo "Performing BLAST search for sequence: $seq_id"
        echo "$line" > query.fasta  # Create a temporary query file
        blastp -query query.fasta -db "$blast_database" -out "blast_res/${seq_id}_blast_result.txt" -outfmt 6
        rm query.fasta  # Remove temporary query file
    fi
done < "$input_file"
