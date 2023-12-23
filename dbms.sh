#!/bin/bash
if mkdir ./DBMS 2> .error.log
then 
	echo "Database is created successfully"
else 
	echo "Permission denied or directory is already existing"
fi
if cd DBMS 2> .error.log
then
	echo " "
else
	echo "DBMS is not founssd"
	exit
fi
# Function to create a new database
create_database() {
  
    read -p "Enter the database name: " db_name
    mkdir $db_name
    echo "Database '$db_name' created successfully."
}

# Function to list existing databases
list_databases() {

        echo "Available databases:"
        ls -1 
	

}

# Function to connect to a specific database
connect_to_database() {
 	
    read -p "Enter the database name: " db_name
    if [ -d "$db_name" ]; then
        echo "Connected to database '$db_name'."
        current_database="$db_name"
        show_database_menu
    else
        echo "Database '$db_name' not found."
    fi
  
   
}

# Function to drop a database
drop_database() {
 

    read -p "Enter the database name to drop: " db_name
    if [ -d "$db_name" ]; then
        rm -r "$db_name"
        echo "Database '$db_name' dropped successfully."
    else
        echo "Database '$db_name' not found."
    fi
  
}

# Function to display the database menu
show_database_menu() {
    PS3="Enter Your Option:"
    options=("Create Table" "List Tables" "Drop Table" "Insert into Table" "Select From Table" "Delete From Table" "Update Table" "Exit Database Menu")
    select opt in "${options[@]}"; do
        case $opt in
            "Create Table")
                create_table
                ;;
            "List Tables")
                list_tables
                ;;
            "Drop Table")
                drop_table
                ;;
            "Insert into Table")
                insert_into_table
                ;;
            "Select From Table")
                select_from_table
                ;;
            "Delete From Table")
                delete_from_table
                ;;
            "Update Table")             
		update_table
                ;;
            "Exit Database Menu")
                echo "Exiting Database Menu."
                break
                ;;
            *)
                echo "Invalid option. Please choose again."
                ;;
        esac
    done
}

# Function to create a new table
create_table() {
    read -p "Enter the table name: " table_name
    if [ -f "$current_database/$table_name" ]
    then
	echo " this table is already existing"
else	
    touch "$current_database/$table_name"
    read -p "Enter column names and datatypes (e.g., col1:int col2:string): " columns
     echo "$columns" | tr ' ' '\n' > "$current_database/$table_name.schema"
    pk_check=false

    while [ "$pk_check" = false ]; do
        echo "Choose the primary key:"
	column_names=$(echo "$columns")

        if [ -n "$column_names" ]; then
            select primaryKeyCol in $column_names; do
                if [ -n "$primaryKeyCol" ]; then
                    echo "$primaryKeyCol:primarykey" >> "$current_database/$table_name.schema2"
                    pk_check=true
                    break
                else
                    echo "Invalid Choice"
                fi
            done
	    
        else
            echo "No columns found in the schema. Please add columns."
            break
        fi
    done
     fi
    echo "Table '$table_name' created successfully."
   
   
}


# Function to list tables in the current database
list_tables() {
    if [ ! -d $current_database ]
    then
    echo "There is no table found"
    else
    echo "Tables in '$current_database':"
    ls -1 "$current_database" | grep -vE '\.schema[0-9]*$'

    fi
}

# Function to drop a table
drop_table() {
          if [ ! -d $current_database ]
    then
    echo "There is no table found"
    else
    read -p "Enter the table name to drop: " table_name
    if [ -f "$current_database/$table_name" ]; then
        rm "$current_database/$table_name" "$current_database/$table_name.schema"
        echo "Table '$table_name' dropped successfully."
    else
        echo "Table '$table_name' not found."
    fi
	  fi
    
}


insert_into_table() {
    read -p "Enter the table name: " table_name

    if [ ! -f "$current_database/$table_name.schema" ]; then
        echo "Table '$table_name' does not exist."
        return
    fi

    columns=$(awk -F: '{print $1}' "$current_database/$table_name.schema")
    data_types=$(awk -F: '{print $2}' "$current_database/$table_name.schema")

    read -p "Enter data for columns: " data_values
    num_values=$(echo "$data_values" | wc -w)

    if [ "$num_values" -ne $(echo "$columns" | wc -w) ]; then
        echo "Number of values entered doesn't match the number of columns."
        echo "Please provide data for all columns: $columns"
        return
    fi

    valid_data=true
    idx=1

    # Validate data types in the input values
    for value in $data_values; do
        data_type=$(echo "$data_types" | head -n "$idx" | tail -n 1 )
        result=$(validate_data_type "$value" "$data_type")
        if [ "$result" != "valid" ]; then
            valid_data=false
            break  # Break the loop on invalid data
        fi
        ((idx++))
    done
 

    if [ "$valid_data" = false ]; then
        echo "Invalid data types entered. Insertion failed."
        return
    fi

    # Proceed with insertion logic based on data validity
    if [ ! -s "$current_database/$table_name" ]; then
        echo "$data_values" > "$current_database/$table_name"
        echo "Data inserted into '$table_name' successfully."
    else
        # Check for the primary key constraint (if applicable)
        if grep -q ":primarykey" "$current_database/$table_name.schema2"; then
            pk_column=$(grep ":primarykey" "$current_database/$table_name.schema2" | cut -d":" -f1)
            pk_index=$(echo "$columns" | grep -o -w -n "$pk_column" | cut -d":" -f1)
            pk_value=$(echo "$data_values" | cut -d" " -f$pk_index)

            # Check if the primary key value already exists
            if grep -q -w "$pk_value" "$current_database/$table_name"; then
                echo "Primary key value '$pk_value' already exists. Insertion failed."
                return
            fi
        fi

        # Insert the data
        echo "$data_values" >> "$current_database/$table_name"
        echo "Data inserted into '$table_name' successfully."
    fi
}

validate_data_type() {
    value=$1
    data_type=$2

    case $data_type in
        int)
            if [[ $value =~ ^[0-9]+$ ]]; then
                echo "valid" # Valid integer
            else
                echo "invalid" # Invalid integer
            fi
            ;;
        string)
            if [[ $value =~ ^[a-zA-Z]+$ ]]; then
                echo "valid" # Valid string
            else
                echo "invalid" # Invalid string
            fi
            ;;
        *)
            echo "invalid" # Unknown data type
            ;;
    esac
}


# Function to select from a table
select_from_table() {
    read -p "Enter the table name: " table_name
    if [ -f "$current_database/$table_name" ]; then
        read -p "Do you want to select the whole table or a specific row (table/row)? " selection
        case "$selection" in
            table)
                echo "Data in '$table_name':"
                cat "$current_database/$table_name" | column -t
                ;;
            row)
                schema_file="$current_database/$table_name.schema2"
                if grep  ":primarykey" "$schema_file"; then
                    pk_column=$(grep ":primarykey" "$schema_file" | cut -d":" -f1)
                    read -p "Enter the value for $pk_column: " pk_value
                    grep -w "$pk_value" "$current_database/$table_name" | column -t
                else
                    echo "Primary key not defined. Unable to select a specific row."
                fi
                ;;
            *)
                echo "Invalid selection."
                ;;
        esac
    else
        echo "Table '$table_name' not found."
    fi
}


# Function to delete from a table
delete_from_table() {
    read -p "Enter the table name: " table_name
 
    if [ -f "$current_database/$table_name" ]; then
        schema_file="$current_database/$table_name.schema2"
 
        if grep ":primarykey" "$schema_file"; then
            pk_column=$(grep ":primarykey" "$schema_file" | cut -d":" -f1)
            read -p "Enter the value for $pk_column: " pk_value
 
            if [[ $pk_value =~ ^[0-9]+$ ]]; then
                if grep -q "\<$pk_value\>" "$current_database/$table_name"; then
                    sed -i "/\<$pk_value\>/d" "$current_database/$table_name"
                    echo "Row with primary key '$pk_value' has been deleted successfully."
                else
                    echo "Row with primary key '$pk_value' does not exist in the table."
                fi
            else
                echo "Invalid input: Not an integer."
            fi
        else
            echo "Primary key not defined. Unable to select a specific row."
        fi
    else
        echo "Table '$table_name' not found."
    fi
}
 
# Function to update a table
update_table() {
   
    read -p "Enter the table name: " table_name
    if [ -f "$current_database/$table_name" ]; then
        schema_file="$current_database/$table_name.schema2"
        if grep -q ":primarykey" "$schema_file"; then
            read -p "Do you want to update the whole row based on the primary key or update a field (row/field)? " choice
            case "$choice" in
                row)
                    pk_column=$(grep ":primarykey" "$schema_file" | cut -d":" -f1)
                    read -p "Enter the value for $pk_column: " pk_value
		   if grep -q "\<$pk_value\>" "$current_database/$table_name"; then
                    read -p "Enter the new data for the row: " new_row_data
		    sed -i "/\<$pk_value\>/c$new_row_data" "$current_database/$table_name"
                    echo "Row updated in '$table_name' based on the primary key."

                else
                    echo "Row with primary key '$pk_value' does not exist in the table."
		    return
                fi
                    ;;
                field)
                    pk_column=$(grep ":primarykey" "$schema_file" | cut -d":" -f1)
                    read -p "Enter the value for $pk_column: " pk_value
		    if grep -q "\<$pk_value\>" "$current_database/$table_name"; then
                    echo "Row updated in '$table_name' based on the primary key."
                    read -p "Enter the field to update: " field                    
                    read -p "Enter the its new value: " field_update
                    sed -i "/\<$pk_value\>/s/\<$field\>/$field_update/" "$current_database/$table_name"
                    echo "Field updated in '$table_name' based on the primary key."

                else
                    echo "Row with primary key '$pk_value' does not exist in the table."
                    return
                fi
                    ;;
                *)
                    echo "Invalid choice."
                    ;;
            esac
        else
            echo "Primary key not defined for table '$table_name'. Unable to perform update based on the primary key."
        fi
    else
        echo "Table '$table_name' not found."
    fi


}

# Main menu
PS3="Enter Your Option: "
options=("Create Database" "List Databases" "Connect To Database" "Drop Database" "Exit")
                select opt in "${options[@]}"; do
    case $opt in
        "Create Database")
            create_database
            ;;
        "List Databases")
            list_databases
            ;;
        "Connect To Database")
            connect_to_database
            ;;
        "Drop Database")
            drop_database
            ;;
        "Exit")
            echo "Exiting..."
            break
            ;;
        *)
            echo "Invalid option. Please choose again."
            ;;
    esac
done
                   