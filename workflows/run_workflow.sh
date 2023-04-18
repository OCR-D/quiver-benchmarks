#!/bin/bash

# $1: complete Path of a workflow to execute

ROOT=$PWD
WORKFLOW_DIR="$ROOT"/workflows
OCRD_WORKFLOW_DIR="$WORKFLOW_DIR"/ocrd_workflows
WORKSPACE_DIR="$WORKFLOW_DIR"/workspaces
WORKFLOW_NAME=$(basename -s .txt "$1")

set -euo pipefail

convert_ocrd_wfs_to_NextFlow() {
    cd "$OCRD_WORKFLOW_DIR" || exit

    echo "Convert OCR-D workflows to NextFlow …"

    mkdir -p "$WORKFLOW_DIR/nf-results"
    FILES=( "$1" "dinglehopper_eval.txt" )
    for FILE in "${FILES[@]}"; do
        if [[ ! -f "$FILE".nf ]]; then
            oton convert -I "$FILE" -O "$FILE".nf
            # the venv part is not needed since we execute this in an image derived from ocrd/all:maximum
            sed -i 's/source "${params.venv_path}"//g' "$FILE".nf
            sed -i 's/deactivate//g' "$FILE".nf
        fi
    done
}

download_models() {
    echo "Download the necessary models if not available"
    if [[ ! -f /usr/local/share/tessdata/Fraktur_GT4HistOCR.traineddata ]]
    then
        ocrd resmgr download ocrd-tesserocr-recognize '*'
    fi
    if [[ ! -d /usr/local/share/ocrd-resources/ocrd-calamari-recognize/qurator-gt4histocr-1.0 ]]
    then
        ocrd resmgr download ocrd-calamari-recognize qurator-gt4histocr-1.0
    fi
}

create_wf_specific_workspaces() {
    # execute this workflow on the existing data (incl. evaluation)
    if [[ ! -d "$WORKSPACE_DIR" ]]; then
        mkdir "$WORKSPACE_DIR"
    fi
    cd "$WORKSPACE_DIR" || exit

    # create workspace for all OCR workflows.
    # each workflow has a separate workspace to work with.
    echo "Create workflow specific workspaces for each dir in ./gt …"
    for DIR in "$ROOT"/gt/*/; do
        DIR_NAME=$(basename "$DIR")
        if [[ ! $DIR_NAME == "reichsanzeiger-gt" ]]; then
            echo "Create workflow specific workspace ""$DIR_NAME""_""$WORKFLOW_NAME""."
            DEST_DIR="$WORKSPACE_DIR"/"$DIR_NAME"_"$WORKFLOW_NAME"
            cp -r "$ROOT"/gt/"$DIR_NAME" "$DEST_DIR"
            cp "$OCRD_WORKFLOW_DIR"/"$1".nf "$DEST_DIR"/data/*/
            cp "$OCRD_WORKFLOW_DIR"/*eval.txt.nf "$DEST_DIR"/data/*/
        fi
    done
}

execute_wfs_and_extract_benchmarks() {
    mkdir -p "$ROOT"/workflows/results
    # for all data sets…
    for WS_DIR in "$WORKSPACE_DIR"/*
    do
        DIR_NAME=$(basename "$WS_DIR")
        if [[ -d "$WS_DIR" && $DIR_NAME == *"$WORKFLOW_NAME" ]]; then
            echo "Switching to $WS_DIR."

            DIR_NAME=$(basename "$WS_DIR")
            run "$WS_DIR"/data/*/*ocr.txt.nf "$DIR_NAME" "$WS_DIR" || echo "An error occurred while processing $WS_DIR. See the logs for more info."
            run "$WS_DIR"/data/*/*eval.txt.nf "$DIR_NAME" "$WS_DIR" || echo "An error occurred while evaluating $WS_DIR. See the logs for more info."

            # create a result JSON according to the specs          
            echo "Get Benchmark JSON …"
            OCR_WF_DIR=$(dirname "$WS_DIR"/data/*/*ocr.txt.nf)
            quiver benchmarks-extraction "$WS_DIR"/data/* "$OCR_WF_DIR"/"$1".nf
            echo "Done."

            # move data to results dir
            mv "$WS_DIR"/data/*/*result.json "$WORKFLOW_DIR"/results
        fi
    done
    cd "$ROOT" || exit
}

adjust_workflow_settings() {
    # $1: $WORKFLOW
    # $2: $DIR_NAME
    sed -i "s CURRENT app/workflows/workspaces/$2/data/*/ g" "$1"
}

rename_and_move_nextflow_result() {
    # rename NextFlow results in order to properly match them to the workflows
    # $1: $WORKFLOW
    # $2: $DIR_NAME
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
    adjust_workflow_settings "$1" "$2"
    nextflow run "$1" -with-weblog http://127.0.0.1:8000/nextflow/ || echo "Error while running $1."
    rename_and_move_nextflow_result "$1" "$2"
    save_workspaces "$3"/data "$2"
}

save_workspaces() {
    # $1: $WS_DIR
    # $2: $DIR_NAME
    echo "Zipping workspace $1"
    ocrd -l ERROR zip bag -d "$DIR_NAME"/data/* -i "$DIR_NAME"/data/* "$DIR_NAME"
    mv "$WORKSPACE_DIR"/"$2".zip "$WORKFLOW_DIR"/results/"$2"_"$WORKFLOW_NAME".zip
}

check_and_run_webserver() {
    IS_WEBSERVER_PORT_OPEN=$(nc -z 127.0.0.1 8000; echo $?)
    if [[ ! "$IS_WEBSERVER_PORT_OPEN" ]]; then
        uvicorn api:app --app-dir "$ROOT"/src & # start webserver for evaluation
    fi
}

convert_ocrd_wfs_to_NextFlow "$1"
download_models
create_wf_specific_workspaces "$1"
check_and_run_webserver
execute_wfs_and_extract_benchmarks "$1"
