from pathlib import Path

import click

from .benchmark_extraction import make_result_json
from .mongodb import post_to_mongodb
from .run import run_workflow


@click.group()
def cli():
    pass

@cli.command('benchmarks-extraction', help="Extracts all relevant metrics from the metadata and NextFlow files.")
@click.argument('WORKSPACE_PATH')
def benchmark_extraction_cli(workspace_path):
    mets_path = Path(workspace_path) / 'mets.xml'
    dictionary = make_result_json(workspace_path, mets_path)
    workspace_name = Path(workspace_path).name
    print(f'Posting {workspace_name} to mongodb')
    post_to_mongodb(dictionary)

@cli.command('run-ocr', help='Runs one or more OCR-D workflows on all data given in the Ground Truth directory (./gt).')
@click.option('-wf', '--workflows', help='Worfklow(s) to run. May be passed multiple times. Default: all', default=['all'], multiple=True)
def run_workflows(workflows):
    for wf in workflows:
        run_workflow(wf)
