#!/bin/bash

ROOT=$PWD
WORKFLOW_DIR="$ROOT"/workflows
OCRD_WORKFLOW_DIR="$WORKFLOW_DIR"/ocrd_workflows
WORKSPACE_DIR="$WORKFLOW_DIR"/workspaces

if [[ -d  workflows/workspaces ]]; then
    rm -rf workflows/workspaces
fi

if [[ -d  workflows/nf-results ]]; then
    rm -rf workflows/nf-results
fi

if [[ -d  workflows/results ]]; then
    rm -rf workflows/results
fi

set -euo pipefail

adjust_workflow_settings() {
    # $1: $WORKFLOW
    # $2: $DIR_NAME
    sed -i "s CURRENT app/workflows/workspaces/$2 g" "$1"
}

rename_and_move_nextflow_result() {
    # rename NextFlow results in order to properly match them to the workflows
    # $1: $WORKFLOW
    # $2: $DIR_NAME
    WORKFLOW_NAME=$(basename -s .txt.nf "$1")
    rm "$WORKFLOW_DIR"/nf-results/*process_completed.json
    mv "$WORKFLOW_DIR"/nf-results/*_completed.json "$WORKFLOW_DIR"/results/"$2"_"$WORKFLOW_NAME"_completed.json
    if [ $WORKFLOW_NAME != "dinglehopper_eval" ]; then
        for DIR in "$WORKSPACE_DIR"/work/*
        do
            WORK_DIR_NAME=$(basename $DIR)
            for SUB_WORK_DIR in $DIR/*
            do
                SUB_WORK_DIR_NAME=$(basename $SUB_WORK_DIR)
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
    nextflow run "$1" -with-weblog http://127.0.0.1:8000/nextflow/
    rename_and_move_nextflow_result "$1" "$2"
    save_workspaces "$3" "$2" "$1"
}

save_workspaces() {
    # $1: $WS_DIR
    # $2: $DIR_NAME
    # $3: $WORKFLOW
    echo "Zipping workspace $1"
    ocrd zip bag -d $1 -i $1 $1
    WORKFLOW_NAME=$(basename -s .txt.nf "$3")
    mv "$WORKSPACE_DIR"/"$2".zip "$WORKFLOW_DIR"/results/"$2"_"$WORKFLOW_NAME".zip
}

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

# download the necessary models if not available
echo "Download the necessary models if not available"
if [[ ! -f /usr/local/share/ocrd-resources/ocrd-tesserocr-recognize/ ]]
then
    mkdir -p /usr/local/share/ocrd-resources/
    ocrd resmgr download ocrd-tesserocr-recognize '*'
fi
if [[ ! -d /usr/local/share/ocrd-resources/ocrd-calamari-recognize/qurator-gt4histocr-1.0 ]]
then
    mkdir -p /usr/local/share/ocrd-resources/
    ocrd resmgr download ocrd-calamari-recognize qurator-gt4histocr-1.0
fi

# execute this workflow on the existing data (incl. evaluation)
mkdir -p "$WORKSPACE_DIR"/tmp
cd "$WORKSPACE_DIR" || exit

# create workspace for all OCR workflows.
# each workflow has a separate workspace to work with.

echo "Restore OCR-D workspaces from BagIts and create workflow specific workspaces …"
for BAGIT in "$ROOT"/submodules/quiver-data/*.zip
do
    BAGIT_NAME=$(basename -s .ocrd.zip "$BAGIT")
    ocrd zip spill "$BAGIT" -d "$WORKSPACE_DIR"/tmp > "$WORKSPACE_DIR"/log.log
    unzip "$BAGIT" METADATA.yml -d "$WORKSPACE_DIR"/tmp/"$BAGIT_NAME"

    for WORKFLOW in "$OCRD_WORKFLOW_DIR"/*ocr.txt.nf
    do
        WF_NAME=$(basename -s .txt.nf "$WORKFLOW")
        cp -r "$WORKSPACE_DIR"/tmp/"$BAGIT_NAME" "$WORKSPACE_DIR"/tmp/"$BAGIT_NAME"_"$WF_NAME"
        cp "$WORKFLOW" "$WORKSPACE_DIR"/tmp/"$BAGIT_NAME"_"$WF_NAME"/
    done
    rm -r "$WORKSPACE_DIR"/tmp/"$BAGIT_NAME"
done

echo "Clean up intermediate dirs …"
for DIR in "$WORKSPACE_DIR"/tmp/*
do
    DIR_NAME=$(basename "$DIR")
    mv "$DIR" "$WORKSPACE_DIR"/"$DIR_NAME"
    cp "$OCRD_WORKFLOW_DIR"/*eval.txt.nf "$WORKSPACE_DIR"/"$DIR_NAME"
done

rm -rf "$WORKSPACE_DIR"/tmp
rm -rf "$WORKSPACE_DIR"/log.log

# start webserver for evaluation
uvicorn api:app --app-dir "$ROOT"/src &

mkdir -p "$ROOT"/workflows/results

# for all data sets…
for WS_DIR in "$WORKSPACE_DIR"/*
do
    if [ -d "$WS_DIR" ]; then
        echo "Switching to $WS_DIR."

        DIR_NAME=$(basename $WS_DIR)

        run "$WS_DIR"/*ocr.txt.nf "$DIR_NAME" "$WS_DIR"
        run "$WS_DIR"/*eval.txt.nf "$DIR_NAME" "$WS_DIR"

        # create a result JSON according to the specs          
        echo "Get Benchmark JSON …"
        quiver benchmarks-extraction "$WS_DIR" "$WORKFLOW"
        echo "Done."

        # move data to results dir
        mv "$WS_DIR"/*.json "$WORKFLOW_DIR"/results
    fi
done

cd "$ROOT" || exit

# summarize JSONs
echo "Summarize JSONs to one file …"
quiver summarize-benchmarks
echo "Done."

echo "Cleaning up …"
rm -rf "$WORKSPACE_DIR"
rm -rf "$ROOT"/work
rm -rf "$WORKFLOW_DIR"/nf-results
rm -rf "$WORKFLOW_DIR"/results
rm "$WORKFLOW_DIR"/ocrd_workflows/*.nf
