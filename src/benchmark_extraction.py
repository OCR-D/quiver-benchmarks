"""This module is responsible for creating the resulting JSON file of the
benchmarking. It extracts the relevant information from the NextFlow processes. """

import json
import re
import xml.etree.ElementTree as ET
from os import listdir, scandir
from statistics import stdev, median
from typing import Any, Dict, List, Union

import yaml
from .constants import METS, RESULTS, QUIVER_MAIN, OCRD


def make_result_json(workspace_path: str, mets_path: str) -> Dict[str, Union[str, Dict]]:
    data_name = get_workspace_name(workspace_path)
    return {
        'eval_workflow_id': 'wf-data'+ data_name + '-eval',
        'label': 'Workflow on data ' + data_name,
        'metadata': make_metadata(workspace_path, mets_path),
        'evaluation_results': extract_benchmarks(workspace_path, mets_path)
    }

def get_workspace_name(workspace_path: str) -> str:
    return workspace_path.split('/')[-1]

def make_metadata(workspace_path: str, mets_path: str) -> Dict[str, Union[str, Dict]]:
    return {
            'ocr_workflow': get_workflow(workspace_path, 'ocr'),
            'eval_workflow': get_workflow(workspace_path, 'eval'),
            'gt_workspace': get_gt_workspace(workspace_path),
            'ocr_workspace': get_workspace(workspace_path, 'ocr'),
            'eval_workspace': get_workspace(workspace_path, 'evaluation'),
            'workflow_steps': get_workflow_steps(mets_path),
            'workflow_model': get_workflow_model(mets_path),
            'eval_tool': get_eval_tool(mets_path),
            'document_metadata': get_document_metadata(workspace_path)
        }

def get_workflow(workspace_path: str, wf_type: str) -> Dict[str, str]:
    if wf_type == 'eval':
        pattern = r'eval.txt.nf'
    else:
        pattern = r'ocr.txt.nf'

    for file in listdir(workspace_path):
        result = re.search(pattern, file)
        if result:
            workflow = file.split('.')[0]
    url = f'{QUIVER_MAIN}/workflows/ocrd_workflows/{workflow}.txt'
    if wf_type == 'ocr':
        wf_name = 'OCR'
    else:
        wf_name = 'Evaluation'
    label = f'{wf_name} Workflow {workflow}'
    return {'@id': url,
        'label': label
    }

def get_workspace(workspace_path: str, ws_type: str) -> Dict[str, str]:
    workspace = get_workspace_name(workspace_path)
    url = f'{QUIVER_MAIN}/workflows/results/{workspace}_{ws_type}.zip'
    if ws_type == 'ocr':
        ws_name = 'OCR'
    else:
        ws_name = 'Evaluation'
    label = f'{ws_name} workspace for {workspace}'
    return {
        '@id': url,
        'label': label
    }

def get_node_from_mets(mets_path: str, xpath: str) -> List[str]:
    with open(mets_path, 'r', encoding='utf-8') as f:
        tree = ET.parse(f)
        return tree.findall(xpath)

def get_workflow_steps(mets_path: str) -> List[str]:
    xpath = f'.//{METS}agent[@ROLE="OTHER"]'
    agents = get_node_from_mets(mets_path, xpath)
    result = []
    for agent in agents:
        iterator = list(agent.iter())
        name = iterator[1].text.split(' ')[0]
        if 'ocrd-dinglehopper' not in name:
            params = iterator[-2].text
            result.append({"id": name, "params": json.loads(params)})

    return result

def get_workflow_model(mets_path: str) -> str:
    try:
        xpath = f'.//{METS}agent[@OTHERROLE="recognition/text-recognition"]/{METS}note[@{OCRD}option="parameter"]'
        parameters = get_node_from_mets(mets_path, xpath)[0].text
        params_json = json.loads(parameters)
        return params_json['checkpoint_dir']
    except:
        xpath = f'.//{METS}agent[@OTHERROLE="layout/segmentation/region"]/{METS}note[@{OCRD}option="parameter"]'
        parameters = get_node_from_mets(mets_path, xpath)[-1].text
        params_json = json.loads(parameters)
        return params_json['model']


def get_eval_tool(mets_path: str) -> str:
    xpath = f'.//{METS}agent[@OTHERROLE="recognition/text-recognition"]/{METS}name'
    return get_node_from_mets(mets_path, xpath)[0].text

def get_gt_workspace(workspace_path: str) -> Dict[str, str]:
    current_workspace = get_workspace_name(workspace_path)
    split_workspace_name = current_workspace.split('_')
    workspace_name_wo_workflow = split_workspace_name[0] + '_' + split_workspace_name[1] + '_' + split_workspace_name[2]
    font = ''
    if split_workspace_name[1] == 'ant':
        font = 'Antiqua'
    elif split_workspace_name[1] == 'frak':
        font = 'Black letter'
    else:
        font = 'Font Mix'
    url = 'https://github.com/OCR-D/quiver-data/blob/main/' + workspace_name_wo_workflow + '.ocrd.zip'
    label = f'GT workspace {split_workspace_name[0]}th century {font} {split_workspace_name[2]} layout'
    return {
        '@id': url,
        'label': label
    }

def get_document_metadata(workspace_path: str) -> Dict[str, Dict[str, str]]:
    result = {
        'data_properties': {
            'fonts': '',
            'publication_century': '',
            'publication_decade': '',
            'publication_year': '',
            'number_of_pages': get_no_of_pages(workspace_path),
            'layout': ''
        }
    }
    with open(workspace_path + '/METADATA.yml', 'r', encoding='utf-8') as file:
        metadata = yaml.safe_load(file)
        scripts = metadata['script']
        fonts = []
        for script in scripts:
            if script == 'Latn':
                fonts.append('Antiqua')
            if script == 'Goth':
                fonts.append('Black Letter')
            if script == 'Hebr':
                fonts.append('Hebrew')
            if script == 'Grek':
                fonts.append('Ancient Greek')
        result['data_properties']['fonts'] = fonts

        earliest = metadata['time']['notBefore']
        latest = metadata['time']['notAfter']
        publication_century = int(earliest[:2]) + 1
        result['data_properties']['publication_century'] = f'{earliest}-{latest}'
        result['data_properties']['publication_year'] = f'{publication_century}th century'

        result['data_properties']['layout'] = metadata['title'].split('_')[-1]
    return result

def get_no_of_pages(workspace_path: str) -> int:
    img_path = workspace_path + '/OCR-D-IMG'
    return len(listdir(img_path))


def extract_benchmarks(workspace_path: str, mets_path: str) -> Dict[str, Dict[str, Any]]:
    json_dirs = get_eval_jsons(workspace_path)

    return {
        'document_wide': make_document_wide_eval_results(workspace_path),
        'by_page': make_eval_results_by_page(json_dirs, mets_path)
    }

def make_document_wide_eval_results(workspace_path: str) -> Dict[str, Union[float, List[float]]]:
    return {
        'wall_time': get_nextflow_time(workspace_path, 'wall'),
        'cpu_time': get_nextflow_time(workspace_path, 'CPU'),
        'cer_mean': get_mean_cer(workspace_path, 'SEG-LINE'),
        'cer_median': get_cer_median(workspace_path, 'SEG-LINE'),
        'cer_range': get_cer_range(workspace_path, 'SEG-LINE'),
        'cer_standard_deviation': get_cer_standard_deviation(workspace_path, 'SEG-LINE'),
        'wer': get_mean_wer(workspace_path, 'SEG-LINE'),
        'pages_per_minute': get_pages_per_minute(workspace_path)
    }


def get_nextflow_completed_process_file(workspace_path: str):
    result_path = workspace_path + RESULTS
    workspace_name = get_workspace_name(workspace_path)

    for file_name in listdir(result_path):
        if 'ocr_completed' in file_name and workspace_name in file_name:
            completed_file = file_name

    with open(result_path + completed_file, 'r', encoding='utf-8') as f:
        file = json.load(f)
    return file

def get_nextflow_time(workspace_path: str, time_type: str) -> float:
    files = listdir(workspace_path)
    logs = []
    for file in files:
        if '.command.log' in file:
            logs.append(file)

    time_per_workflow_step = []
    for log in logs:
        with open(workspace_path + '/' + log, 'r', encoding='utf-8') as l:
            log_file = l.read()
            no_sec_s = re.search(rf'([0-9]+?\.[0-9]+?)s \({time_type}\)', log_file).group(1)
            time_per_workflow_step.append(float(no_sec_s))
    return sum(time_per_workflow_step)


def get_pages_per_minute(workspace_path: str) -> float:
    duration = get_nextflow_time(workspace_path, 'wall')
    no_pages = get_no_of_pages(workspace_path)

    return no_pages / (duration / 60)


def get_mean_cer(workspace_path: str, gt_type: str) -> float:
    cers = get_error_rates_for_gt_type(workspace_path, gt_type, 'cer')
    return sum(cers) / len(cers)


def get_cer_median(workspace_path: str, gt_type: str) -> float:
    cers = get_error_rates_for_gt_type(workspace_path, gt_type, 'cer')
    return median(cers)


def get_cer_standard_deviation(workspace_path: str, gt_type: str) -> float:
    cers = get_error_rates_for_gt_type(workspace_path, gt_type, 'cer')
    if len(cers) > 1:
        return stdev(cers)
    else:
        return None


def get_mean_wer(workspace_path: str, gt_type: str) -> float:
    wers = get_error_rates_for_gt_type(workspace_path, gt_type, 'wer')
    return sum(wers) / len(wers)


def get_error_rates_for_gt_type(workspace_path: str, gt_type: str, error_rate: str) -> List[float]:
    eval_jsons = []
    eval_dir_path = workspace_path + '/OCR-D-EVAL-' + gt_type + '/'
    for file_name in listdir(eval_dir_path):
        if 'json' in file_name:
            eval_jsons.append(file_name)
    ers = []
    for eval_json in eval_jsons:
        with open(eval_dir_path + eval_json, 'r', encoding='utf-8') as f:
            json_file = json.load(f)
            ers.append(json_file[error_rate])
    return ers

def get_cer_range(workspace_path: str, gt_type: str) -> List[float]:
    cers = get_error_rates_for_gt_type(workspace_path, gt_type, 'cer')
    return [min(cers), max(cers)]

def make_eval_results_by_page(json_dirs: str, mets_path: str) -> List[object]:
    result = []
    for d in json_dirs:
        for file_path in json_dirs[d]:
            result.append(get_metrics_for_page(file_path, mets_path))

    return result

def get_eval_dirs(workspace_dir: str) -> List[str]:
    list_subfolders_with_paths = [f.path for f in scandir(workspace_dir) if f.is_dir()]
    eval_dirs = [name for name in list_subfolders_with_paths if re.search('EVAL', name)]
    return eval_dirs


def get_eval_jsons(workspace_dir: str) -> Dict[str, List[str]]:
    eval_dirs = get_eval_dirs(workspace_dir)
    result = {}
    for eval_dir in eval_dirs:
        files_in_dir = [f.path for f in scandir(eval_dir) if f.is_file()]
        json_files = [name for name in files_in_dir if re.search('json', name)]
        result[eval_dir] = sorted(json_files)
    return result


def get_page_id(json_file_path: str, mets_path: str) -> str:
    json_file_name = get_file_name_from_path(json_file_path)
    gt_file_name = json_file_name.replace('EVAL', 'GT')
    xpath = f'.//{METS}fptr[@FILEID="{gt_file_name}"]/..'
    return get_node_from_mets(mets_path, xpath)[0].attrib['ID']


def get_file_name_from_path(json_file_path: str) -> str:
    json_file_name = json_file_path.split('/')[-1]
    name_wo_ext = json_file_name.split('.')[0]
    return name_wo_ext


def get_metrics_for_page(json_file_path: str, mets_path: str) -> Dict[str, Union[str, float]]:
    with open(json_file_path, 'r', encoding='utf-8') as file:
        eval_file = json.load(file)

    return {
        'page_id': get_page_id(json_file_path, mets_path),
        'cer': eval_file['cer'],
        'wer': eval_file['wer']
    }
