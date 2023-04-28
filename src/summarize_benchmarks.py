#!/usr/bin/env python

import json
from os import getcwd, listdir, stat
from pathlib import Path

ID_MAP_PATH = Path('/app/data/id_map.json')

def process_results():
    files = get_result_json_files()
    make_id_map_json(files)
    summarize(files)

def make_id_map_json(file_list):
    if stat(ID_MAP_PATH).st_size == 0:
        print('Create ID file from scratch.')
        with open(ID_MAP_PATH, 'w', encoding='utf-8') as outfile:
            dic = {}
            for f in file_list:
                new_filename = get_basename_wo_ext(f)
                target_file = f'data/files/{new_filename}.json'
                dic[new_filename] = target_file
                make_new_result_json_for_wf(target_file)
            json_object = json.dumps(dic, indent=None)
            outfile.write(json_object)
    else:
        with open(ID_MAP_PATH, 'r', encoding='utf-8') as read_file:
            id_map_data = json.load(read_file)
        new_entries_list = get_new_id_map_entries(file_list, id_map_data)
        if len(new_entries_list) > 0:
            print('Add new workspaces to ID file.')
            with open(ID_MAP_PATH, 'w', encoding='utf-8') as outfile:
                for entry in new_entries_list:
                    new_entry = {entry: target_file}
                    id_map_data.update(new_entry)
                    json.dump(id_map_data, outfile)

def get_basename_wo_ext(abs_path_to_file: str) -> str:
    return Path(abs_path_to_file).stem.split('.')[0]

def make_new_result_json_for_wf(path: str):
    with open(path, 'a', encoding='utf-8') as outfile:
        json.dump([], outfile)

def get_new_id_map_entries(file_list, id_map_data):
    new_entries = []
    for f in file_list:
        new_filename = get_basename_wo_ext(f)
        target_file = f'data/files/{new_filename}.json'
        if not new_filename in id_map_data.keys():
            new_entries.append(new_filename)
            make_new_result_json_for_wf(target_file)
    return new_entries

def get_result_json_files():
    json_loc = getcwd() + '/workflows/results/'
    file_list = [ json_loc + x for x in listdir(json_loc) if x.endswith("result.json") ]
    return file_list

def summarize(json_files):
    print("Copy results to their corresponding files at data/files/…")
    for file in json_files:
        with open(file, 'r', encoding='utf-8') as f:
            new_data = json.load(f)

        file_name = get_basename_wo_ext(file)
        target = f'data/files/{file_name}.json'
        target_data = []
        with open(target, 'r', encoding='utf-8') as target_file:
            try:
                contents = target_file.read()
                target_data = json.loads(contents)
            except json.JSONDecodeError:
                print(f'Could not load JSON data from {target}.')
        with open(target, 'w', encoding='utf-8') as target_file:
            target_data.append(new_data)
            json.dump(target_data, target_file)
    print("Done.")
