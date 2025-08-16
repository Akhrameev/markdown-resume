#!/usr/bin/env bash

set -e

# --- Argument Validation ---
if [ "$#" -lt 1 ] || [ "$#" -gt 3 ] || ! [ -f "$1" ]; then
  echo "Usage:" >&2
  echo "$0 src/filename.md (pdf|html)" >&2
  exit 1
fi

if [[ "pdf" != "$2" ]] && [[ "html" != "$2" ]]; then
  echo "invalid format, expected 'pdf' or 'html', got '$2'" >&2
  exit 1
fi

# --- Variable Setup ---
sourcefile="$1"
format="$2"
source_base=$(basename "$sourcefile" .md)
output_file="output/$source_base.$format"

# --- Style Detection ---
STYLE=$(pandoc -s "$sourcefile" --template=extract_style.txt)

if [ -z "$STYLE" ]; then
  echo "style not set in markdown front matter, using default" >&2
  STYLE=default
fi

if [ ! -d "styles/$STYLE" ]; then
  echo "style '$STYLE' doesn't exist, using default" >&2
  STYLE=default
else
  echo "using '$STYLE' style" >&2
fi

# --- Pandoc Command ---
# Get a list of CSS files for the selected style
# shellcheck disable=SC2012
styles=$(ls -p styles/${STYLE}/*.css | sed "s/^/-c /" | tr "\n" " ")

# Base options for both HTML and PDF
# Note: --self-contained is deprecated. Using --embed-resources --standalone instead.
PANDOC_OPTS="-s --embed-resources --standalone -t html $styles"

echo "Creating $output_file..."

# We actually want the spaces to split out the args
# shellcheck disable=SC2086
if [ "$format" = "pdf" ]; then
  # Use --pdf-engine=weasyprint and REMOVE the incompatible option
  pandoc $PANDOC_OPTS "$sourcefile" -o "$output_file" --pdf-engine=weasyprint
else
  # For HTML, just run the command without PDF options
  pandoc $PANDOC_OPTS "$sourcefile" -o "$output_file"
fi
