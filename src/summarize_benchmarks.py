#!/usr/bin/env python

import json
from os import getcwd, listdir
from pathlib import Path


def get_json_files():
    json_loc = getcwd() + '/workflows/results/'
    file_list = [ json_loc + x for x in listdir(json_loc) if x.endswith("result.json") ]
    return file_list

def summarize_to_one_file(json_files):
    print("Summarize JSONs to one file …")
    result = []
    for file in json_files:
        with open(file, 'r', encoding='utf-8') as f:
            data = json.load(f)
            result.append(data)
    output_path = getcwd() + '/data/workflows.json'
    json_str = json.dumps(result, indent=4)
    Path(output_path).write_text(json_str, encoding='utf-8')
    print("Done.")
