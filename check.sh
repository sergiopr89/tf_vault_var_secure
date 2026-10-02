#!/bin/bash

TF_DIR="$1"

if [[ -z "$TF_DIR" || ! -d "$TF_DIR" ]]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

find "$TF_DIR" -type f -name "*.tf" -print0 | while IFS= read -r -d '' TF_FILE; do

    RELATIVE_FILE="${TF_FILE#$TF_DIR/}"

    # Remove multiline comments and single-line comments before | awk
    OUTPUT=$(
    sed -E '
        :a
        /\/\*/{
            N
            /\*\//!ba
            s/\/\*([^*]|\*+[^*\/])*\*+\///g
        }
        s/#.*$//
    ' "$TF_FILE" | awk '
    BEGIN {
        in_variable = 0
        variable_name = ""
        brace_count = 0
        has_ephemeral = 0
        has_sensitive = 0
    }

    # Start of a variable block
    /^[[:space:]]*variable[[:space:]]+/ {

        # Validate previous variable, if any
        if (in_variable && variable_name ~ /^vault_(role_id|secret_id)/) {
            if (has_ephemeral && has_sensitive) {
                print "OK: variable \"" variable_name "\""
            } else {
                print "ERROR: variable \"" variable_name "\" must have ephemeral = true and sensitive = true"
            }
        }

        # Extract variable name, with or without quotes
        variable_name = $0
        sub(/^[[:space:]]*variable[[:space:]]+/, "", variable_name)
        sub(/[[:space:]]*\{.*/, "", variable_name)
        gsub(/"/, "", variable_name)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", variable_name)

        in_variable = 1
        has_ephemeral = 0
        has_sensitive = 0

        # Count braces
        line = $0
        opens = gsub(/{/, "{", line)
        closes = gsub(/}/, "}", line)
        brace_count = opens - closes

        next
    }

    # Inside variable block
    in_variable {

        # Match ephemeral = true, allowing arbitrary whitespace
        if ($0 ~ /^[[:space:]]*ephemeral[[:space:]]*=[[:space:]]*true[[:space:]]*$/) {
            has_ephemeral = 1
        }

        # Match sensitive = true, allowing arbitrary whitespace
        if ($0 ~ /^[[:space:]]*sensitive[[:space:]]*=[[:space:]]*true[[:space:]]*$/) {
            has_sensitive = 1
        }

        # Count braces
        line = $0
        opens = gsub(/{/, "{", line)
        closes = gsub(/}/, "}", line)
        brace_count += opens - closes

        # End of variable block
        if (brace_count <= 0) {

            if (variable_name ~ /^vault_(role_id|secret_id)/) {
                if (!has_ephemeral || !has_sensitive) {
                    print "ERROR: variable \"" variable_name "\" must have ephemeral = true and sensitive = true"
                }# else {
                #    print "OK: variable \"" variable_name "\""
                #}
            }

            in_variable = 0
            variable_name = ""
        }
    }

    # Validate last block if file does not end cleanly
    END {
        if (in_variable && variable_name ~ /^vault_(role_id|secret_id)/) {
            if (!has_ephemeral || !has_sensitive) {
                print "ERROR: variable \"" variable_name "\" must have ephemeral = true and sensitive = true"
            }# else {
            #    print "OK: variable \"" variable_name "\""
            #}
        }
    }
    ')
    
    if [[ -n "$OUTPUT" ]]; then
        echo "$OUTPUT" | sed "s|^|$RELATIVE_FILE: |"
    fi

done