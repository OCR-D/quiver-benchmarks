import json
from os import getcwd
from pathlib import Path
from typing import Dict, Union

from fastapi import FastAPI

app = FastAPI()


@app.post("/nextflow/")
def save_workflow(item: Dict[str, Union[str, float,Dict]]):
    event = item['event']
    output_name = item['runName'] + '_' + item['runId']
    output = getcwd() + '/../nf-results/' + output_name + '_' + event + '.json'
    json_str = json.dumps(item, indent=4, sort_keys=True)
    Path(output).write_text(json_str, encoding='utf-8')
