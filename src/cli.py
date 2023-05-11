import json
from pathlib import Path

import click

from .benchmark_extraction import make_result_json
from .summarize_benchmarks import get_json_files, summarize_to_one_file


@click.group()
def cli():
    pass

@cli.command('benchmarks-extraction', help="...")
@click.argument('WORKSPACE_PATH')
@click.argument('WORKFLOW_PATH')
def benchmark_extraction_cli(workspace_path, workflow_path):
    workflow_name = Path(workflow_path).stem
    workspace_name = Path(workspace_path).name
    mets_path = Path(workspace_path) / 'mets.xml'
    dictionary = make_result_json(workspace_path, mets_path)
    json_object = json.dumps(dictionary, indent=4)
    output = Path(workspace_path, f'{workspace_name}_{workflow_name}_result.json')
    with open(output, 'w', encoding='utf-8') as outfile:
        outfile.write(json_object)

@cli.command('summarize-benchmarks', help="...")
def summarize_benchmarks_cli():
    summarize_to_one_file(get_json_files())
    print("Successfully summarized JSON files!")
