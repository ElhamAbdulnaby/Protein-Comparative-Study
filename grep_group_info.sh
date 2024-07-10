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



declare -A sequences  # Associative array to store unique sequences
x=0

# Read data from the input file and populate the sequences array
unique_groups=()

# Iterate through each line of the input file
while IFS=$'\t' read -r entry protein_families_gene protein_families domain_ft; do
    # Extract the part before underscore in the "Protein families_Gene" column
    group=$(echo "$protein_families_gene" | cut -d'_' -f1 | sort -u)
    # Add the group to the array if it's not already there
    if [[ ! " ${unique_groups[@]} " =~ " ${group} " ]]; then
        unique_groups+=("$group")
    fi
done < modified_data/$selection.tsv
num_lines=$(wc -l < "modified_data/$selection.tsv")

# Print the unique groups with corresponding numbers
echo "Available groups:"
for ((i=1; i<${#unique_groups[@]}; i++)); do
    echo "$((i)): ${unique_groups[i]}"
done 
# Prompt the user to select a group by number
read -p "Enter the number corresponding to the group you want to choose: " group_selection



# Validate user input
if [[ $group_selection =~ ^[0-9]+$ ]] && (( group_selection > 0 && group_selection <= ${#unique_groups[@]} )); then
    selected_group=${unique_groups[group_selection]}
    echo "You selected group: $selected_group"
else
    echo "Invalid selection. Please enter a valid number."
fi 
fasta_file="groups_fasta/${selected_group}_$selection.fasta"
echo "fasta_file: $fasta_file"
echo -n > "$fasta_file"
num_domain=0
num_of_gp_items=0
total_length=0
while IFS=$'\t' read -r entry protein_families_gene protein_families domain_ft; do
    if [[ "$entry" != "Entry" ]]; then
        echo "$x of $num_lines - $entry"
         x=$((x+1))
        # Check if the protein_families_gene starts with the user input
        if [[ "$protein_families_gene" == $selected_group* ]]; then
            
            num_of_gp_items=$((num_of_gp_items+1))

            url="https://www.uniprot.org/uniprot/$entry.fasta"
            fetched_sequence=$(wget -qO- "$url" | grep -v '>' | tr -d '\n')
            #echo length of fetched_sequence is "$fetched_sequence"
            if [ -n "$fetched_sequence" ]; then
                # echo "-----"$domain_ft
                list_of_seq=()
                for domain in $(echo "$domain_ft" | grep -oE 'DOMAIN [0-9]+..[0-9]+' | grep -oE '[0-9]+..[0-9]+'); do
                    num_domain=$((num_domain+1))
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
                total_length=$((total_length + ${#concatenated_sequence}))
                echo "Total Length of All sequences: $total_length"
                echo ">$protein_families_gene" >> "$fasta_file"
                echo "$concatenated_sequence" >> "$fasta_file"
                
            else
                # If fetched_sequence is null or empty, skip further processing
                echo "Skipping entry because fetched_sequence is null or empty"
            fi
           
        fi    
    fi
done < modified_data/$selection.tsv  
num_lines=$(wc -l < "$fasta_file")
echo "the combined fasta sequences data conatined $num_lines rows has been saved into the file $fasta_file"

average_length=$((total_length / num_of_gp_items))
echo "Number of proteins in this group $selected_group " :$num_of_gp_items
echo "This protein has:  $num_domain domains"
echo "This group '$selected_group' has an average length of $average_length for concatenated domains."


