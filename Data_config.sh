#!/bin/bash

echo "we will fetch data with the query in index $1" 
keywords=("AGC+OR+CAMK+OR+CK1+OR+CMGC+OR+NEK+protein+kinase" "typical+protein+kinase" "((family:%22adenylyl+cyclase%22)+AND+GUC)+OR+STE+OR+(family:%22Tyr+protein+kinase%22)+OR+TKL+kinase")

echo "Select a query:"
for ((i=0; i<${#keywords[@]}; i++)); do
    echo "$i: ${keywords[$i]}"
done
read -p "Selected query number is : " index
if [ ! "$index" ] || [ "$index" -gt $(( ${#keywords[@]} - 1 )) ]; then
    echo "Error: allowed only from 0 to $(( ${#keywords[@]} - 1 ))"
    exit 1
fi
query="(${keywords[$index]})+AND+(model_organism:9606)+AND+(reviewed:true)"
url="https://rest.uniprot.org/uniprotkb/search?fields=accession,id,protein_name,gene_names,length,protein_families,ft_domain&format=tsv&query=$query&size=500"
output_path="modified_data/$index.tsv"
curl -o data.tsv $url
items=("AGC" "CAMK" "CK1" "CMGC" "NEK" "RGC" "STE" "TKL" "TYR" "cyclase")
x=0
# Read the data from a file (the data is stored in a file named "data.tsv")
while IFS=$'\t' read -r entry entry_name protein_names gene_names length protein_families domain_ft; do
     ((x++))  # Increment x
        matched=false
        # Convert protein_families to lowercase
        protein_families_lower=$(echo "$protein_families" | tr '[:upper:]' '[:lower:]')
        
        # Iterate over items array
        for item in "${items[@]}"; do
            # Convert item to lowercase
            item_lower=$(echo "$item" | tr '[:upper:]' '[:lower:]')
            # Check if protein_families contains item (case-insensitive)
            if [[ "$protein_families_lower" == *"$item_lower"* ]]; then
                # Update protein_families with corresponding list name
                protein_families="$item"
                matched=true
                break  # Exit loop if match found
            fi
        done

        # If no match found, set protein_families to "other"
       if [[ "$matched" == false && $x -gt 1 ]]; then
            protein_families="other"
        fi
        # Extract the gene name from the gene names
        gene_name=$(echo "$gene_names" | cut -d' ' -f1)
        # Concatenate the entry name with the gene name
        new_entry_name="${protein_families}_${gene_name}"

        # Print the modified row
        echo -e "$entry\t$new_entry_name\t$protein_families\t$gene_names\t$length\t$domain_ft;"
done < data.tsv > $output_path

echo "the modified data conatined $x rows has been saved into the file $output_path"
