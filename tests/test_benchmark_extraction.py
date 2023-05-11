"""
Tests for quiver/benchmark_extraction.py
"""

from pathlib import Path

from quiver.benchmark_extraction import (get_cer_range,
                                         get_document_metadata, get_eval_dirs,
                                         get_eval_jsons, get_eval_tool,
                                         get_gt_workspace, get_mean_cer,
                                         get_mean_wer,
                                         get_metrics_for_page, get_no_of_pages,
                                         get_page_id, get_workflow,
                                         get_workflow_model,
                                         get_workflow_steps, get_workspace,
                                         get_cer_median,
                                         get_cer_standard_deviation,
                                         get_nextflow_time)
from quiver.constants import QUIVER_MAIN

WORKSPACE_DIR = str(Path(__file__).parent / 'assets/benchmarking/16_ant_complex_minimal_ocr')
METS_PATH = str(Path(__file__).parent / 'assets/benchmarking/16_ant_complex_minimal_ocr/mets.xml')

def test_get_eval_dirs():
    result = get_eval_dirs(WORKSPACE_DIR)
    expected = [f'{WORKSPACE_DIR}/OCR-D-EVAL-SEG-LINE',
        f'{WORKSPACE_DIR}/OCR-D-EVAL-SEG-BLOCK',
        f'{WORKSPACE_DIR}/OCR-D-EVAL-SEG-PAGE']

    assert result == expected

def test_get_eval_jsons():
    result = get_eval_jsons(WORKSPACE_DIR)
    expected = {
        f'{WORKSPACE_DIR}/OCR-D-EVAL-SEG-BLOCK':
            [f'{WORKSPACE_DIR}/OCR-D-EVAL-SEG-BLOCK/OCR-D-EVAL-SEG-BLOCK_0007.json',
            f'{WORKSPACE_DIR}/OCR-D-EVAL-SEG-BLOCK/OCR-D-EVAL-SEG-BLOCK_0008.json',
            f'{WORKSPACE_DIR}/OCR-D-EVAL-SEG-BLOCK/OCR-D-EVAL-SEG-BLOCK_0009.json'],
        f'{WORKSPACE_DIR}/OCR-D-EVAL-SEG-LINE':
            [f'{WORKSPACE_DIR}/OCR-D-EVAL-SEG-LINE/OCR-D-EVAL-SEG-LINE_0007.json',
            f'{WORKSPACE_DIR}/OCR-D-EVAL-SEG-LINE/OCR-D-EVAL-SEG-LINE_0008.json',
            f'{WORKSPACE_DIR}/OCR-D-EVAL-SEG-LINE/OCR-D-EVAL-SEG-LINE_0009.json'],
        f'{WORKSPACE_DIR}/OCR-D-EVAL-SEG-PAGE':
            [f'{WORKSPACE_DIR}/OCR-D-EVAL-SEG-PAGE/OCR-D-EVAL-SEG-PAGE_0007.json',
            f'{WORKSPACE_DIR}/OCR-D-EVAL-SEG-PAGE/OCR-D-EVAL-SEG-PAGE_0008.json',
            f'{WORKSPACE_DIR}/OCR-D-EVAL-SEG-PAGE/OCR-D-EVAL-SEG-PAGE_0009.json']
    }

    assert result ==expected

def test_get_page_id():
    json_file_path = f'{WORKSPACE_DIR}/OCR-D-EVAL-SEG-BLOCK/OCR-D-EVAL-SEG-BLOCK_0007.json'
    result = get_page_id(json_file_path, METS_PATH)
    expected = 'phys_0007'

    assert result == expected

def test_get_metrics_for_page():
    expected = {
            'page_id': 'phys_0007',
            'cer': 0.07124352331606218,
            'wer': 0.2231404958677686
        }

    json_file = f'{WORKSPACE_DIR}/OCR-D-EVAL-SEG-BLOCK/OCR-D-EVAL-SEG-BLOCK_0007.json'
    result = get_metrics_for_page(json_file, METS_PATH)

    assert result == expected

def test_get_mean_cer():
    result = get_mean_cer(WORKSPACE_DIR, 'SEG-LINE')

    assert result == 0.10240852523716282

def test_get_mean_wer():
    result = get_mean_wer(WORKSPACE_DIR, 'SEG-LINE')

    assert result == 0.23466068901129858

def test_cer_get_range():
    result = get_cer_range(WORKSPACE_DIR, 'SEG-LINE')

    assert result == [0.07124352331606218, 0.1306122448979592]

def test_get_eval_tool():
    result = get_eval_tool(METS_PATH)
    assert result == 'ocrd-dinglehopper vNone'

def test_get_workflow_model():
    result = get_workflow_model(METS_PATH)
    assert result == 'Fraktur_GT4HistOCR'

def test_get_workflow_steps():
    mets_path = 'tests/assets/benchmarking/16_ant_complex_minimal_ocr/mets.xml'
    result = get_workflow_steps(mets_path)
    print(result)
    assert result == [{'id': 'ocrd-tesserocr-recognize',
        'params': {
        'segmentation_level': 'region',
        'textequiv_level': 'word',
        'find_tables': True,
        'model': 'Fraktur_GT4HistOCR',
        'dpi': 0,
        'padding': 0,
        'overwrite_segments': False,
        'overwrite_text': True,
        'shrink_polygons': False,
        'block_polygons': False,
        'find_staves': False,
        'sparse_text': False,
        'raw_lines': False,
        'char_whitelist': '',
        'char_blacklist': '',
        'char_unblacklist': '',
        'tesseract_parameters': {},
        'xpath_parameters': {},
        'xpath_model': {},
        'auto_model': False,
        'oem': 'DEFAULT'
    }}]

def test_get_gt_workspace():
    result = get_gt_workspace(WORKSPACE_DIR) 
    assert result['@id'] == 'https://github.com/OCR-D/quiver-data/blob/main/16_ant_complex.ocrd.zip'
    assert result['label'] == 'GT workspace 16th century Antiqua complex layout'

def test_get_ocr_workflow():
    result = get_workflow(WORKSPACE_DIR, 'ocr')
    assert result['@id'] == f'{QUIVER_MAIN}/workflows/ocrd_workflows/minimal_ocr.txt'
    assert result['label'] == 'OCR Workflow minimal_ocr'

def test_get_eval_workflow():
    result = get_workflow(WORKSPACE_DIR, 'eval')
    assert result['@id'] == f'{QUIVER_MAIN}/workflows/ocrd_workflows/dinglehopper_eval.txt'
    assert result['label'] == 'Evaluation Workflow dinglehopper_eval'

def test_get_eval_workflow():
    workspace_path = 'tests/assets/benchmarking/16_ant_complex_minimal_ocr/'
    result = get_workflow(workspace_path, 'eval')
    assert result['@id'] == 'https://github.com/OCR-D/quiver-back-end/blob/main/workflows/ocrd_workflows/dinglehopper_eval.txt'
    assert result['label'] == 'Evaluation Workflow dinglehopper_eval'

def test_get_eval_workspace():
    result = get_workspace(WORKSPACE_DIR, 'evaluation')
    assert result['@id'] == f'{QUIVER_MAIN}/workflows/results/16_ant_complex_minimal_ocr_evaluation.zip'
    assert result['label'] == 'Evaluation workspace for 16_ant_complex_minimal_ocr'

def test_get_ocr_workspace():
    result = get_workspace(WORKSPACE_DIR, 'ocr')
    assert result['@id'] == f'{QUIVER_MAIN}/workflows/results/16_ant_complex_minimal_ocr_ocr.zip'
    assert result['label'] == 'OCR workspace for 16_ant_complex_minimal_ocr'

def test_get_document_metadata():
    result = get_document_metadata(WORKSPACE_DIR)
    assert result['data_properties']['fonts'] == ['Antiqua']
    assert result['data_properties']['publication_year'] == '16th century'
    assert result['data_properties']['publication_decade'] == ''
    assert result['data_properties']['publication_century'] == '1500-1600'
    assert result['data_properties']['number_of_pages'] == 3
    assert result['data_properties']['layout'] == 'complex'

def test_get_no_of_pages():
    result = get_no_of_pages(WORKSPACE_DIR)
    assert result == 3

def test_get_cer_median():
    result = get_cer_median(WORKSPACE_DIR, 'SEG-LINE')
    assert result == 0.10536980749746708

def test_get_cer_standard_deviation():
    result = get_cer_standard_deviation(WORKSPACE_DIR, 'SEG-LINE')
    assert result == 0.02979493530847308

def test_get_nextflow_time():
    result = get_nextflow_time(WORKSPACE_DIR, 'CPU')
    assert result == 10.418373

def test_get_wall_time():
    result = get_nextflow_time(WORKSPACE_DIR, 'wall')
    assert result == 7.995512
