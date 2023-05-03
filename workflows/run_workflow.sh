#!/bin/bash

# $1: complete Path of a workflow to execute

ROOT=$PWD
WORKFLOW_DIR="$ROOT"/workflows
OCRD_WORKFLOW_DIR="$WORKFLOW_DIR"/ocrd_workflows
WORKSPACE_DIR="$WORKFLOW_DIR"/workspaces
WORKFLOW_NAME=$(basename -s .txt "$1")
RESULTS_DIR="$WORKFLOW_DIR"/results

set -euo pipefail

prepare_dirs() {
    if [[ -d  workflows/nf-results ]]; then
        rm -rf workflows/nf-results
    fi
    mkdir -p "$WORKSPACE_DIR"
    mkdir -p "$RESULTS_DIR"
    mkdir workflows/nf-results
    mkdir -p data/files
    touch data/id_map.json
}

convert_ocrd_wfs_to_NextFlow() {
    cd "$OCRD_WORKFLOW_DIR" || exit

    echo "Convert OCR-D workflows to NextFlow …"

    FILES=( "$1" "dinglehopper_eval.txt" )
    for FILE in "${FILES[@]}"; do
        if [[ ! -f "$FILE".nf ]]; then
            oton convert -I "$FILE" -O "$FILE".nf
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
    cd "$WORKSPACE_DIR" || exit

    # create workspace for all OCR workflows.
    # each workflow has a separate workspace to work with.
    echo "Create workflow specific workspaces for each dir in ./gt …"
    for DIR in "$ROOT"/gt/*/; do
        DIR_NAME=$(basename "$DIR")
        if [[ ! $DIR_NAME == "reichsanzeiger-gt" ]]; then
            DEST_DIR="$WORKSPACE_DIR"/"$DIR_NAME"_"$WORKFLOW_NAME"
            if [[ ! -d "$DEST_DIR" ]]; then
                echo "Create workflow specific workspace ""$DEST_DIR""."
                cp -r "$ROOT"/gt/"$DIR_NAME" "$DEST_DIR"
                cp "$OCRD_WORKFLOW_DIR"/"$1".nf "$DEST_DIR"/data/*/
                cp "$OCRD_WORKFLOW_DIR"/*eval.txt.nf "$DEST_DIR"/data/*/
            else
                echo "$DEST_DIR already exists. Skipping."
            fi
        fi
    done
}

execute_wfs_and_extract_benchmarks() {
    # for all data sets…
    for WS_DIR in "$WORKSPACE_DIR"/*/
    do
	if [ "$WS_DIR" != "/app/workflows/workspaces/work/" ]; then
        DATA_DIR="$WS_DIR"/data
        DIR_NAME=$(basename "$WS_DIR")
        INNER_DIR=$(ls "$DATA_DIR"/)
        if [[ -d "$WS_DIR" && $DIR_NAME == *"$WORKFLOW_NAME" ]] ; then
            if ! grep -q "OCR-D-OCR" "$WS_DIR/data/$INNER_DIR/mets.xml"; then
                echo "Switching to $WS_DIR."

                run "$DATA_DIR"/*/*ocr.txt.nf "$DIR_NAME"
                run "$DATA_DIR"/*/*eval.txt.nf "$DIR_NAME"

                # create a result JSON according to the specs          
                echo "Get Benchmark JSON …"
                OCR_WF_DIR=$(dirname "$WS_DIR"/data/*/*ocr.txt.nf)
                quiver benchmarks-extraction "$WS_DIR"/data/* "$OCR_WF_DIR"/"$1".nf
                echo "Done."

                # move data to results dir
                mv "$DATA_DIR"/*/*result.json "$RESULTS_DIR"
            else
                echo "$WS_DIR has already been processed."
            fi
        fi
	fi
    done
    cd "$ROOT" || exit
}

rename_and_move_nextflow_result() {
    # rename NextFlow results in order to properly match them to the workflows
    # $1: $WORKFLOW
    # $2: $DIR_NAME
    LOCAL_WORKFLOW_NAME=$(basename -s .txt.nf "$1")
    if [ "$LOCAL_WORKFLOW_NAME" != "dinglehopper_eval" ]; then
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
    nextflow run "$1" -with-weblog http://127.0.0.1:8000/nextflow/ --mets_path "/app/workflows/workspaces/$2/data/*/mets.xml"
    rename_and_move_nextflow_result "$1" "$2"
    save_workspaces "$1" "$2"
}

save_workspaces() {
    # $1: $WORKFLOW
    # $2: $DIR_NAME
    echo "Zipping workspace $2"
    DATA_DIR="$2/data/"
    if basename -s .txt.nf "$1" | grep "eval"; then
        LOCAL_WORKFLOW_NAME=$(basename -s .txt.nf "$1")
        ocrd -l ERROR zip bag -d "$DATA_DIR"/* -i "$DATA_DIR"/* "$RESULTS_DIR"/"$2"_"$LOCAL_WORKFLOW_NAME".zip
    else
        ocrd -l ERROR zip bag -d "$DATA_DIR"/* -i "$DATA_DIR"/* "$RESULTS_DIR"/"$2".zip
    fi
}

check_and_run_webserver() {
    IS_WEBSERVER_PORT_OPEN=$(nc -z 127.0.0.1 8000; echo $?)
    if [[ ! "$IS_WEBSERVER_PORT_OPEN" ]]; then
        uvicorn api:app --app-dir "$ROOT"/src & # start webserver for evaluation
    fi
}

prepare_dirs
convert_ocrd_wfs_to_NextFlow "$1"
download_models
create_wf_specific_workspaces "$1"
check_and_run_webserver
execute_wfs_and_extract_benchmarks "$1"
