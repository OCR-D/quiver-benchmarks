from .constants import WORKFLOW_DIR
from pathlib import Path
from os import listdir
import subprocess

def run_workflow(workflow):
    if workflow == 'all':
        run_all_workflows()
    else:
        run_single_workflow(workflow)

def run_all_workflows():
    for wf in listdir(WORKFLOW_DIR):
        pass

def run_single_workflow(workflow):
    cmd = f'bash /app/workflows/run_workflow.sh {workflow}'
    subprocess.run(cmd, shell=True, check=True)
