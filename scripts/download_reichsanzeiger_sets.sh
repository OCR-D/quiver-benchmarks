#!/bin/sh

echo "Download Reichsanzeiger GT repository."
cd gt || exit
if [ ! -d reichsanzeiger-gt ]; then
    git clone https://github.com/UB-Mannheim/reichsanzeiger-gt
fi

cd .. || exit


PREFIX="data_srcs"
files=(
    "$PREFIX"/reichsanzeiger_many_ads.list
    "$PREFIX"/reichsanzeiger_random.list
    "$PREFIX"/reichsanzeiger_tables.list
    "$PREFIX"/reichsanzeiger_title_pages.list
)

for FILE in "${files[@]}"; do
    echo "Processing $FILE."
    NAME=$(basename "$FILE" .list)
    mkdir -p gt/"$NAME"/OCR-D-IMG
    mkdir -p gt/"$NAME"/OCR-D-GT-SEG-LINE

    urlbase=`echo "aHR0cHM6Ly9kaWdpLmJpYi51bmktbWFubmhlaW0uZGUvcmVpY2hzYW56ZWlnZXIuZmNnaT9GSUY9
L3JlaWNoc2FuemVpZ2VyL2ZpbG0vCg==" | base64 -d`
    cat $FILE | while read -r line; do wget --limit-rate=500k "${urlbase}${line% *}" -O ./gt/"$NAME"/OCR-D-IMG/${line#* }; done
done
