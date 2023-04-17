"""
Runs one or all given workflows in /app/workflows/ocrd_workflows
"""

import subprocess
from os import listdir
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

def run_all_workflows():
    """Runs all OCR workflows available in workflows/ocrd_workflows
    """
    for wf in listdir(WORKFLOW_DIR):
        pass

def run_single_workflow(workflow):
    """Runs a single OCR workflow

    Args:
        workflow (string): The name of the OCR workflow file OR 'all'
    """
    cmd = f'bash /app/workflows/run_workflow.sh {workflow}'
    subprocess.run(cmd, shell=True, check=True)
