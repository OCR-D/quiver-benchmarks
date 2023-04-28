#!/usr/bin/env python

import json
from os import getcwd, listdir, stat
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

def make_id_map_json():
    files = get_json_files()
    PATH = Path('/app/data/id_map.json')

    if stat('data/id_map.json').st_size == 0:
        with open(PATH, 'w', encoding='utf-8') as outfile:
            dic = {}
            for f in files:
                new_filename = get_basename_wo_ext(f)
                dic[new_filename] = f'data/files/{new_filename}.json'
            json_object = json.dumps(dic, indent=None)
            outfile.write(json_object)
    else:
        with open(PATH, 'r', encoding='utf-8') as read_file:
            data = json.load(read_file)
        new_entries = []
        for f in files:
            new_filename = get_basename_wo_ext(f)
            if not new_filename in data.keys():
                new_entries.append(new_filename)
        if len(new_entries) > 0:
            with open(PATH, 'w', encoding='utf-8') as outfile:
                for entry in new_entries:
                    new_entry = {entry: f'data/files/{entry}.json'}
                    data.update(new_entry)
                    json.dump(data, outfile)

def get_basename_wo_ext(abs_path_to_file: str) -> str:
    return Path(abs_path_to_file).stem.split('.')[0]
