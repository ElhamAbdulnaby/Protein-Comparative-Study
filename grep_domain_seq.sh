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

fasta_file="fasta_seq_files/domainseq_$selection.fasta"
echo "fasta_file: $fasta_file"
echo -n > "$fasta_file"



declare -A sequences  # Associative array to store unique sequences

x=0
# Read data from the input file and populate the sequences array
while IFS=$'\t' read -r entry protein_families_gene protein_families domain_ft; do
    x=$((x+1))
    if [[ "$entry" != "Entry" ]]; then
        echo "$x of $num_lines - $entry"
        url="https://www.uniprot.org/uniprot/$entry.fasta"
        fetched_sequence=$(wget -qO- "$url" | grep -v '>' | tr -d '\n')
        #echo length of fetched_sequence is "$fetched_sequence"
        if [ -n "$fetched_sequence" ]; then
            # echo "-----"$domain_ft
            list_of_seq=()
            for domain in $(echo "$domain_ft" | grep -oE 'DOMAIN [0-9]+..[0-9]+' | grep -oE '[0-9]+..[0-9]+'); do
                range=$(echo "$domain" | grep -oE '[0-9]+..[0-9]+')
                
                start=$(echo "$range" | awk -F '[.]+' '{print $1}')
                end=$(echo "$range" | awk -F '[.]+' '{print $2}')
                echo "Start: $start, End: $end"
                extracted_sequence=$(echo "$fetched_sequence" | cut -c "$start"-"$end")
                list_of_seq+=("$extracted_sequence")
            done
            # echo "Contents of list_of_seq: ${list_of_seq[*]}"

        
            unique_list=()
            for element in "${list_of_seq[@]}"; do
                if [[ ! " ${unique_list[@]} " =~ " $element " ]]; then
                    unique_list+=("$element")
                fi
            done
            concatenated_sequence=$(printf "%s" "${unique_list[@]}")

            if [ -z "$concatenated_sequence" ]; then
                echo "no domain"
                concatenated_sequence="$fetched_sequence"  # If concatenated_sequence is empty, use fetched_sequence
            fi

            # echo "Contents of concatenated_sequence: $concatenated_sequence"
            echo "Length of sequence: ${#concatenated_sequence}"

            
            echo ">$protein_families_gene" >> "$fasta_file"
            echo "$concatenated_sequence" >> "$fasta_file"
         
        else
            # If fetched_sequence is null or empty, skip further processing
            echo "Skipping entry because fetched_sequence is null or empty"
        fi
    fi
done <<< "$(tail -n 1000 "$input_file")"
num_lines=$(wc -l < "$fasta_file")
echo "the combined fasta sequences data conatined $num_lines rows has been saved into the file $fasta_file"


#"$(tail -n 10 "$input_file")" ctrl number of lines