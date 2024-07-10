#!/bin/bash

# Array to store file paths
files=()

# Find all files matching the pattern
shopt -s nullglob

for file in aligned_groups_files/*; do
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

# Input alignment file
alignment_file="aligned_groups_files/$file_name.fasta"

# Read headers from alignment file/ for file contain all groups
#headers=$(grep "^>" "$input_file" | sed 's/>//' | cut -d '_' -f1 | sort -u)

# Print headers to let user choose a group
#echo "Please select a group by its header (* to select all groups):"
#select header in $headers '*'; do
#    if [ -n "$header" ]; then
#        echo "You selected group: $header in file \"$input_file\" "
#        break
#    else
#        echo "Invalid choice, please try again."
#    fi
#done

# Output file for highly conserved sequences in FASTA format/All MSA formate
#output_file="Conserved_seq/highly_cons_seq_file${selection}_${header}.fasta"

# Output file for highly conserved sequences in FASTA format
output_file="Conserved_seq/highly_cons_seq_$file_name.fasta"

# Python script to extract highly conserved sequences within the selected group(s)
python3 - <<EOF
from Bio import AlignIO

alignment_file = "$alignment_file"
selected_group = "$header"
output_file = "$output_file"

# Read the alignment file
alignment = AlignIO.read(alignment_file, "fasta")

# Extract sequences of the selected group(s)
if selected_group == '*':
    selected_sequences = alignment
else:
    selected_sequences = [record for record in alignment if record.id.startswith(selected_group)]

# Calculate conservation percentage for each position within the selected group(s)
alignment_length = len(alignment[0])
conservation_percentages = [sum(record[i] == alignment[0][i] for record in selected_sequences) / len(selected_sequences) for i in range(alignment_length)]

# Identify highly conserved regions (>75% conservation)
highly_conserved_regions = []
for i, percentage in enumerate(conservation_percentages):
    if percentage > 0.75:
        highly_conserved_regions.append(i)

# Extract highly conserved sequences from identified regions, keeping gaps
highly_conserved_sequences = []
for record in selected_sequences:
    highly_conserved_seq = ''.join(record[i] for i in highly_conserved_regions)
    highly_conserved_sequences.append((record.id, highly_conserved_seq))

# Write highly conserved sequences to output file in FASTA format
with open(output_file, "w") as f:
    for record_id, sequence in highly_conserved_sequences:
        f.write(f">{record_id}\n")
        f.write(f"{sequence}\n")

print("Highly conserved sequences within the selected group(s) extracted and saved to:", output_file)

EOF


