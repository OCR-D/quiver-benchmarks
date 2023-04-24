#!/bin/bash

ROOT=$PWD
WORKFLOW_DIR="$ROOT"/workflows
OCRD_WORKFLOW_DIR="$WORKFLOW_DIR"/ocrd_workflows
WORKSPACE_DIR="$WORKFLOW_DIR"/workspaces
RESULTS_DIR="$WORKFLOW_DIR"/results

set -euo pipefail

clean_up_dirs() {
    if [[ -d  workflows/nf-results ]]; then
        rm -rf workflows/nf-results
    fi
}

convert_ocrd_wfs_to_NextFlow() {
    cd "$OCRD_WORKFLOW_DIR" || exit

    echo "Convert OCR-D workflows to NextFlow …"

    mkdir -p "$WORKFLOW_DIR/nf-results"

    for FILE in *.txt
    do
        oton convert -I "$FILE" -O "$FILE".nf
        # the venv part is not needed since we execute this in an image derived from ocrd/all:maximum
        sed -i 's/source "${params.venv_path}"//g' "$FILE".nf
        sed -i 's/deactivate//g' "$FILE".nf
    done
}

download_models() {
    echo "Download the necessary models if not available"
    if [[ ! -f /usr/local/share/tessdata/Fraktur_GT4HistOCR.traineddata ]]
    then
        #mkdir -p /usr/local/share/ocrd-resources/
        ocrd resmgr download ocrd-tesserocr-recognize '*'
    fi
    if [[ ! -d /usr/local/share/ocrd-resources/ocrd-calamari-recognize/qurator-gt4histocr-1.0 ]]
    then
        mkdir -p /usr/local/share/ocrd-resources/
        ocrd resmgr download ocrd-calamari-recognize qurator-gt4histocr-1.0
    fi
}

create_wf_specific_workspaces() {
    # execute this workflow on the existing data (incl. evaluation)
    mkdir -p "$WORKSPACE_DIR"/tmp
    cd "$WORKSPACE_DIR" || exit

    # create workspace for all OCR workflows.
    # each workflow has a separate workspace to work with.
    for DIR in "$ROOT"/gt/*/; do
        DIR_NAME=$(basename "$DIR")
        if [[ ! $DIR_NAME == "reichsanzeiger-gt" ]]; then
            echo "Create workflow specific workspace for $DIR_NAME."
            for WORKFLOW in "$OCRD_WORKFLOW_DIR"/*ocr.txt.nf
            do
                WF_NAME=$(basename -s .txt.nf "$WORKFLOW")
                TARGET_DIR="$WORKSPACE_DIR"/"$DIR_NAME"_"$WF_NAME"
                if [[ ! -d "$TARGET_DIR" ]]; then
                    cp -r "$ROOT"/gt/"$DIR_NAME" "$TARGET_DIR"
                    cp "$WORKFLOW" "$TARGET_DIR"/data/*/
                    cp "$OCRD_WORKFLOW_DIR"/*eval.txt.nf "$TARGET_DIR"/data/*/
                    rm -rf "$WORKSPACE_DIR"/log.log
                else
                    echo "$TARGET_DIR already exists. Skipping."
                fi
            done
        fi
    done
}

execute_wfs_and_extract_benchmarks() {
    mkdir -p "$ROOT"/workflows/results
    # for all data sets…
    for WS_DIR in "$WORKSPACE_DIR"/*
    do
        DATA_DIR="$WS_DIR"/data
        DIR_NAME=$(basename "$WS_DIR")
        INNER_DIR=$(ls "$DATA_DIR"/)

        if ! grep -q "OCR-D-OCR" "$WS_DIR/data/$INNER_DIR/mets.xml" ; then
            echo "Switching to $WS_DIR."            

            run "$DATA_DIR"/*/*ocr.txt.nf "$DIR_NAME" "$WS_DIR"
            run "$DATA_DIR"/*/*eval.txt.nf "$DIR_NAME" "$WS_DIR"

            # create a result JSON according to the specs          
            echo "Get Benchmark JSON …"
            quiver benchmarks-extraction "$DATA_DIR"/* "$WORKFLOW"
            echo "Done."

            # move data to results dir
            mv "$DATA_DIR"/*/*result.json "$RESULTS_DIR"
        else
            echo "$WS_DIR has already been processed."
        fi
    done
    cd "$ROOT" || exit
}

rename_and_move_nextflow_result() {
    # rename NextFlow results in order to properly match them to the workflows
    # $1: $WORKFLOW
    # $2: $DIR_NAME
    WORKFLOW_NAME=$(basename -s .txt.nf "$1")
    if [ "$WORKFLOW_NAME" != "dinglehopper_eval" ]; then
        for DIR in "$WORKSPACE_DIR"/work/*
        do
            WORK_DIR_NAME=$(basename "$DIR")
            for SUB_WORK_DIR in "$DIR"/*
            do
                SUB_WORK_DIR_NAME=$(basename "$SUB_WORK_DIR")
                mv "$WORKSPACE_DIR"/work/"$WORK_DIR_NAME"/"$SUB_WORK_DIR_NAME"/.command.log "$WORKSPACE_DIR"/"$2"/"$WORK_DIR_NAME"_"$SUB_WORK_DIR_NAME".command.log
            done
            
        done
    fi
    rm -rf "$WORKSPACE_DIR"/work/*
    rm "$WORKSPACE_DIR"/.nextflow.log
}

run() {
    # $1: $WORKFLOW
    # $2: $DIR_NAME
    # $3: $WS_DIR
    nextflow run "$1" -with-weblog http://127.0.0.1:8000/nextflow/ --mets_path "/app/workflows/workspaces/$2/data/*/mets.xml"
    rename_and_move_nextflow_result "$1" "$2"
    save_workspaces "$3"/data "$2" "$1"
}

save_workspaces() {
    # $1: $WORKFLOW
    # $2: $DIR_NAME
    # $3: $WS_DIR
    echo "Zipping workspace $3"
    ocrd -l ERROR zip bag -d "$DIR_NAME"/data/* -i "$DIR_NAME"/data/* "$DIR_NAME"
    WORKFLOW_NAME=$(basename -s .txt.nf "$1")
    mv "$WORKSPACE_DIR"/"$2".zip "$RESULTS_DIR"/"$2"_"$WORKFLOW_NAME".zip
}

summarize_to_data_json() {
    # summarize JSONs
    echo "Summarize JSONs to one file …"
    quiver summarize-benchmarks
    echo "Done."
}

clean_up_dirs
convert_ocrd_wfs_to_NextFlow
download_models
create_wf_specific_workspaces
uvicorn api:app --app-dir "$ROOT"/src & # start webserver for evaluation
sleep 2 && >&2 echo "Process is running. See logs at ./logs for more information."
execute_wfs_and_extract_benchmarks
summarize_to_data_json
echo "All workflows have been run."
