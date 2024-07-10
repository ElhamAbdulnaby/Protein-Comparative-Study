#!/bin/bash
# Array to store file paths
files=()

# Find all files matching the pattern
shopt -s nullglob

for file in modified_data/*; do
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

fasta_file="fasta_seq_files/fullseq_$selection.fasta"
echo "fasta_file: $fasta_file"
echo -n > "$fasta_file"

x=0
# Read data from the input file and populate the sequences array
while IFS=$'\t' read -r entry protein_families_gene protein_families domain_ft; do
    x=$((x+1))
    if [[ "$entry" != "Entry" ]]; then
        echo "$x of $num_lines - $entry"
        url="https://www.uniprot.org/uniprot/$entry.fasta"
        fetched_sequence=$(wget -qO- "$url" | grep -v '>' | tr -d '\n')
        #echo length of fetched_sequence is "$fetched_sequence"
        echo ">$protein_families_gene" >> "$fasta_file"
        echo "$fetched_sequence" >> "$fasta_file"
        echo "Length of sequence: ${#fetched_sequence}"
    fi
done <<< "$(tail -n 1000 "$input_file")"
num_lines=$(wc -l < "$fasta_file")
echo "the combined fasta sequences data conatined $num_lines rows has been saved into the file $fasta_file"

 
