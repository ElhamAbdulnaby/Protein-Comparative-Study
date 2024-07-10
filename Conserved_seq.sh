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

# Input alignment file
alignment_file="aligned_seq_files/$selection.fasta"

# Read headers from alignment file
headers=$(grep "^>" "$alignment_file" | sed 's/>//' | cut -d '_' -f1 | sort -u)

# Print headers to let user choose a group
echo "Please select a group by its header (* to select all groups):"
select header in $headers '*'; do
    if [ -n "$header" ]; then
        echo "You selected group: $header in file \"$alignment_file\" "
        break
    else
        echo "Invalid choice, please try again."
    fi
done

# Output file for conserved sequences in FASTA format
output_file="./conserved_seq/conserved_sequences_$selection.fasta"


# Python script to extract conserved sequences within the selected group(s) and keep only two columns of gap between each conserved column
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

# Calculate conservation of each position within the selected group(s)
conserved_positions = [i for i in range(len(alignment[0])) if all(record[i] == alignment[0][i] for record in selected_sequences)]

# Keep only two columns of gap between each conserved column
conserved_sequences_with_gaps = []
for record in selected_sequences:
    conserved_seq_with_gaps = ''
    last_conserved_position = None
    for i in conserved_positions:
        if last_conserved_position is not None and i - last_conserved_position > 2:
            conserved_seq_with_gaps += '-' * 2  # Insert two columns of gaps
        conserved_seq_with_gaps += record[i]
        last_conserved_position = i
    conserved_sequences_with_gaps.append((record.id, conserved_seq_with_gaps))

# Write conserved sequences with gaps to output file in FASTA format
with open(output_file, "w") as f:
    for record_id, sequence in conserved_sequences_with_gaps:
        f.write(f">{record_id}\n")
        f.write(f"{sequence}\n")

print("Conserved sequences within the selected group(s) extracted and saved to:", output_file)
EOF