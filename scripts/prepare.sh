#!/bin/bash

mkdir -p gt
mkdir -p zips

ROOT=$PWD
echo "Prepare OCR-D Ground Truth …"

while IFS= read -r URL; do
    OWNER=$(echo "$URL" | cut -d'/' -f4)
    REPO=$(echo "$URL" | cut -d'/' -f5)
    if [[ ! -d zips/"$REPO" ]]; then
        echo "Downloading $REPO …"
        RESULT=$(curl -L \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/repos/"$OWNER"/"$REPO"/releases/latest)
        ZIP_URLS=$(echo  "$RESULT" | jq -r '.assets | .[].browser_download_url')
        mkdir -p zips/"$REPO"
        for URL in $ZIP_URLS; do
            ZIP_NAME=$(echo $URL | rev | cut -d'/' -f1 | rev)
            if [[ ! -f zips/"$REPO"/"$ZIP_NAME" ]]; then
                echo "Downloading $ZIP_NAME"
                curl -L -o zips/"$REPO"/"$ZIP_NAME".zip "$URL"
            fi
        done
    fi
done < data_srcs/default_data_sources.txt

# the default data is structured like this:
# repository_name
# |___ subordinate_work_1.ocrd.zip.zip
# |___ subordinate_work_2.ocrd.zip.zip
# |___ ...
# |___ metadata-v1234.zip.zip
for REPO in $PWD/zips/*; do
    for ZIP in $REPO/*.zip; do
        echo "Extracting $ZIP…"
        ID=$(echo "$ZIP" | cut -d'.' -f1 | rev | cut -d'/' -f1 | rev)
        unzip -qq -o "$ZIP" -d "$REPO"/"$ID"
    done

    for DIR in "$REPO"/*/; do
        #rm -rf $DIR
        if [[ ! -f "$DIR"/metadata.json ]]; then
            cp "$REPO"/metadata*/metadata_out/metadata.json "$DIR"/metadata.json
        fi
        if [[ "$DIR" =~ "metadata" ]]; then
            echo "Skipping $DIR"
        else
            ID=$(echo "$DIR" | rev | cut -d'/' -f2 | rev)
            mkdir "$DIR"tmp
            mv "$DIR"data/* "$DIR"tmp
            mkdir -p "$DIR"data/"$ID"
            mv "$DIR"tmp/* "$DIR"data/"$ID"
            rm -rf "$DIR"tmp
            mv "$DIR" "$ROOT"/gt
        fi
    done

    for DIR in "$REPO"/*/; do
        if [[ "$DIR" =~ "metadata" ]]; then
            rm -rf "$DIR"
        fi
    done
done


echo "Prepare Reichsanzeiger GT …"

if [[ $1 == "ra-full" ]]; then
    echo "Preparing the full Reichsanzeiger GT."

    if [ ! -d reichsanzeiger-gt ]; then
        git clone https://github.com/UB-Mannheim/reichsanzeiger-gt
    fi

    RA_GT=/gt/reichsanzeiger-gt
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
    
    python3 scripts/convert-yml-to-json.py --indent 2 $RA_GT/METADATA.yml $RA_GT/metadata.json
    
    echo " … and ready to go!"
   
else
    echo "Prepare smaller sets of Reichsanzeiger GT."
    cd $ROOT || exit
    bash scripts/prepare_reichsanzeiger_sets.sh
fi
