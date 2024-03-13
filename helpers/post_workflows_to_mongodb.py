import os
import requests
import json

# insert the full path to the directory that hold your workflows,
# respectively.
WF_DIR = './workflows/ocrd_workflows'

def get_model(procs: str) -> str:
    recog_proc = find_recognition_proc(procs)
    if recog_proc:
        tokens = recog_proc.split()
        proc_name = tokens[0]
        if proc_name == "calamari-recognize":
            return tokens[tokens.index('checkpoint_dir') + 1]
        if proc_name == "froc-recognize":
            return tokens[tokens.index('network') + 1]
        return tokens[tokens.index('model') + 1]
    return ""

def find_recognition_proc(procs: list) -> str:
    for proc in procs:
        if "recognize" in proc:
            return proc

def get_steps(procs: list, processor_json: list) -> list:
    steps = []
    for proc in procs:
        tokens = proc.split()
        proc_name = f'ocrd-{tokens[0]}'
        processor_params = find_processor(proc_name, processor_json)
        # the first 5 tokens are the processor name, the input and the output group
        if len(tokens) > 5:
            params = tokens[5:]
            cnt = 0
            # override the defaults with custom params
            while cnt < params.count("-P"):
                param_key = params[cnt * 3 + 1]
                param_value = params[cnt * 3 + 2]
                if param_value in ('true', 'True'):
                    param_value = True
                elif param_value in ('false', 'False'):
                    param_value = False
                processor_params['params'][param_key] = param_value
                cnt += 1
        steps.append(processor_params)
    return steps

def find_processor(proc_name: str, processor_json: list) -> dict:
    for entry in processor_json:
        if entry["id"] == proc_name:
            return entry

def sanitize(lines: list) -> list:
    sanitized = []
    for line in lines:
        sanitized.append(line.strip().replace('"', '').replace('\\', ''))
    # the first line contains the `ocrd process` instruction and is
    # unnecessary
    return sanitized[1:]

def post_wf():
    files_in_wf_dir = os.listdir(WF_DIR)
    with open('helpers/ocrd_processors.json', mode='r', encoding='utf-8') as f:
        processor_json = json.load(f)

    purged = []
    for file in files_in_wf_dir:
        if not ('dinglehopper' and '.nf') in file:
            with open(f'{WF_DIR}/{file}', mode='r', encoding='utf-8') as f:
                lines = f.readlines()
                procs = sanitize(lines)
            id_name = file.split('.')[0]
            d = {'@id': id_name,
                'label': f'Workflow {id_name}',
                'steps': get_steps(procs, processor_json),
                'model': get_model(procs)}
            purged.append(d)

    url = 'http://localhost:8084/api/workflows'

    for data in purged:
        r = requests.post(url, json=data, timeout=10)
        print(f'{r.status_code}: {data["@id"]}')

if __name__ == '__main__':
    print('Adding workflow data to the Quiver database.')
    post_wf()
    print('Finished process.')
