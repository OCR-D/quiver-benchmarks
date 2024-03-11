#!/bin/sh

echo "Download Reichsanzeiger GT repository."
cd gt || exit
if [ ! -d reichsanzeiger-gt ]; then
    git clone https://github.com/UB-Mannheim/reichsanzeiger-gt
fi

cd .. || exit

ROOT=$PWD


PREFIX="data_srcs"
files=(
    "$PREFIX"/reichsanzeiger_random.list
)

for FILE in "${files[@]}"; do
    NAME=$(basename "$FILE" .list)
    if [ -d   gt/"$NAME" ]; then
        echo "Directory gt/$NAME already exists. Skipping download."
    else
        echo "Processing $FILE."
        mkdir -p gt/"$NAME"/data/"$NAME"/OCR-D-IMG
        mkdir -p gt/"$NAME"/data/"$NAME"/OCR-D-GT-SEG-LINE

        urlbase=$(echo "aHR0cHM6Ly9kaWdpLmJpYi51bmktbWFubmhlaW0uZGUvcmVpY2hzYW56ZWlnZXIuZmNnaT9GSUY9
L3JlaWNoc2FuemVpZ2VyL2ZpbG0vCg==" | base64 -d)
        while read -r line; do 
            wget --limit-rate=500k "${urlbase}${line% *}" -O ./gt/"$NAME"/data/"$NAME"/OCR-D-IMG/"${line#* }"
            IMG_NAME=$(basename "${line#* }" .jpg)
            cp gt/reichsanzeiger-gt/data/reichsanzeiger-1820-1939/GT-PAGE/"$IMG_NAME".xml gt/"$NAME"/data/"$NAME"/OCR-D-GT-SEG-LINE/"$IMG_NAME".xml
        done < "$FILE"
    fi

    if [ ! -f gt/"$NAME"/mets.xml ]; then
        echo "Preparing OCR-D workspace for $NAME".
        cd gt/"$NAME"/data/"$NAME" || exit
        ocrd workspace init
        ocrd workspace set-id "$NAME"

        FILEGRP="OCR-D-IMG"
        FILEGRP_2="OCR-D-GT-SEG-LINE"
        # add images to mets
        EXT=".jpg"  # the actual extension of the image files
        MEDIATYPE='image/jpeg'  # the actual media type of the image files
        for i in OCR-D-IMG/*"$EXT"; do
            BASE=$(basename "${i}" $EXT)
            ocrd workspace add -G $FILEGRP -i "${FILEGRP}"_"${BASE}" -g P_"${BASE}" -m $MEDIATYPE "${i}"
        done

        # add GT to mets
        for i in "$FILEGRP_2"/*.xml; do
            BASE=$(basename "${i}" ".xml")
            ocrd workspace add -G $FILEGRP_2 -i "${FILEGRP_2}"_"${BASE}" -g P_"${BASE}" -m text/xml "${i}"
        done
    fi

    if [ ! -f "$ROOT"/gt/"$NAME"/metadata.json ]; then
        cp "$ROOT"/gt/reichsanzeiger-gt/METADATA.yml "$ROOT"/gt/"$NAME"/data/"$NAME"/METADATA.yml
        python3 "$ROOT"/scripts/convert-yml-to-json.py --indent 2 "$ROOT"/gt/"$NAME"/data/"$NAME"/METADATA.yml "$ROOT"/gt/"$NAME"/metadata.json
    fi
    cd "$ROOT" || exit
done

echo "Preparation of Reichsanzeiger GT subsets done."
