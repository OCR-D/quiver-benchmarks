#!/bin/bash

mkdir gt

echo "Prepare OCR-D Ground Truth …"

while IFS= read -r URL; do
    OWNER=$(echo "$URL" | cut -d'/' -f4)
    REPO=$(echo "$URL" | cut -d'/' -f5)
    if [[ ! -f gt/"$REPO".zip ]]; then
        echo "Downloading $REPO …"
        RESULT=$(curl -L \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/repos/"$OWNER"/"$REPO"/releases/latest)
        ZIP_URL=$(echo  "$RESULT" | jq -r '.assets | .[].browser_download_url')
        curl -L -o gt/"$REPO".zip "$ZIP_URL"
    fi
done < data_srcs/default_data_sources.txt

cd gt || exit
# the default data is structured like this:
# repository_name.zip
# |___ subordinate_work_1.zip
# |___ subordinate_work_2.zip
# |___ ...
# $ZIP refers to the release itself which is on level "repository_name.zip"
# the subordinate works are also OCR-D BagIts / zips. these are referred to by $INNER_ZIP.
for ZIP in *.zip; do
    NAME=$(echo "$ZIP" | cut -d"." -f1)
    echo "Processing $NAME"
    if [[ ! -d  $NAME && $NAME != "reichsanzeiger-gt" ]]; then 
        unzip -qq -d "$NAME" "$ZIP"
        mv "$NAME"/ocrdzip_out/* "$NAME" && rm -r "$NAME"/ocrdzip_out
        for INNER_ZIP in "$NAME"/*.zip; do
            echo "Dealing with inner zip files …"
            INNER_ZIP_NAME=$(basename "$INNER_ZIP" .ocrd.zip)
            unzip -qq -d "$NAME"/"$INNER_ZIP_NAME" "$INNER_ZIP" && rm "$INNER_ZIP"

            echo "Recreate required directory structure for $INNER_ZIP_NAME."
            mkdir "$NAME"/"$INNER_ZIP_NAME"/data/"$INNER_ZIP_NAME"
            mv "$NAME"/"$INNER_ZIP_NAME"/data/OCR-* "$NAME"/"$INNER_ZIP_NAME"/data/"$INNER_ZIP_NAME"
            mv "$NAME"/"$INNER_ZIP_NAME"/data/mets.xml "$NAME"/"$INNER_ZIP_NAME"/data/"$INNER_ZIP_NAME"
            cp "$NAME"/metadata.json "$NAME"/"$INNER_ZIP_NAME"/data/"$INNER_ZIP_NAME"/metadata.json

            echo "Moving $INNER_ZIP_NAME higher in dir structure."
            mv "$NAME"/"$INNER_ZIP_NAME" .
            echo "Done."
        done
        rm -rf "$NAME"
    fi
done

echo "Prepare Reichsanzeiger GT …"

if [[ $1 == "ra-full" ]]; then
    echo "Preparing the full Reichsanzeiger GT."

    if [ ! -d reichsanzeiger-gt ]; then
        git clone https://github.com/UB-Mannheim/reichsanzeiger-gt
    fi

    RA_GT=/app/gt/reichsanzeiger-gt
    DATA_DIR=/$RA_GT/data
    cd $DATA_DIR|| exit
    
    if [[ -d reichsanzeiger-1820-1939/OCR-D-IMG ]]; then
        echo "Skip downloading Reichsanzeiger images."
    else
        bash download_images.sh
    fi
    cd reichsanzeiger-1820-1939 || exit
    ocrd workspace init
    mkdir OCR-D-IMG
    cp ../images/* OCR-D-IMG
    rm -rf ../images
    rm -rf ../reichsanzeiger-1820-1939_with-TableRegion
    cp -r GT-PAGE OCR-D-GT-SEG-LINE
    
    echo "Adding images to mets …"
    
    FILEGRP="OCR-D-IMG"
    EXT=".jpg"  # the actual extension of the image files
    MEDIATYPE='image/jpeg'  # the actual media type of the image files
    for i in "$FILEGRP"/*"$EXT"; do
      BASE=$(basename "${i}" $EXT);
      ocrd workspace add -G $FILEGRP -i ${FILEGRP}_"${BASE}" -g P_"${BASE}" -m $MEDIATYPE "${i}";
    done
    
    python3 /app/scripts/convert-yml-to-json.py --indent 2 $RA_GT/METADATA.yml $RA_GT/metadata.json
    
    echo " … and ready to go!"
   
else
    echo "Prepare smaller sets of Reichsanzeiger GT."
    cd /app || exit
    bash /app/scripts/prepare_reichsanzeiger_sets.sh
fi
