"""
Runs one or all given workflows in /app/workflows/ocrd_workflows
"""

import subprocess
from glob import glob
from shutil import rmtree
from os import listdir, remove
from fnmatch import fnmatch
from pathlib import Path

from .constants import WORKFLOW_DIR


def run_workflow(workflow):
    """Runs a given or all available workflow(s)

    Args:
        workflow (string): The name of the OCR workflow file OR 'all'
    """
    if workflow == 'all':
        run_all_workflows()
    else:
        run_single_workflow(workflow)
    clean_up()


def run_all_workflows():
    """Runs all OCR workflows available in workflows/ocrd_workflows
    """
    for workflow in glob(f'{WORKFLOW_DIR}/*_ocr.txt'):
        wf_name = f'{Path(workflow).stem}.txt'
        print('++++++++++++++++++++++++++++++')
        print(f'Processing workflow {wf_name}')
        run_single_workflow(wf_name)


def run_single_workflow(workflow):
    """Runs a single OCR workflow

    Args:
        workflow (string): The name of the OCR workflow file OR 'all'
    """
    cmd = f'bash /app/workflows/run_workflow.sh {workflow}'
    subprocess.run(cmd, shell=True, check=True)


def clean_up():
    """Cleans up intermediate directories
    """
    print('Cleaning up …')
    rmtree('/app/workflows/nf-results')

    for filename in listdir(WORKFLOW_DIR):
        if fnmatch(filename, "*.nf"):
            path = f'{WORKFLOW_DIR}/{filename}'
            remove(path)