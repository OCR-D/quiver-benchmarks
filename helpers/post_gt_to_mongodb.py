import os
import json
import requests

# insert the full path to the directory that hold your GT and the workflows,
# respectively.
GT_DIR = './gt'

def make_label(file_name):
    return f'GT workspace {file_name}'

def get_gt_metadata(dir_path):
    with open(f'{dir_path}/metadata.json', mode='r', encoding='utf-8') as metadata:
        return json.load(metadata)

def post_gt():
    files_in_gt_dir = os.listdir(GT_DIR)
    gt = []
    for file in files_in_gt_dir:
        if not 'zip' in file or file == 'reichsanzeiger-gt':
            d = {'gt_workspace':
                 {'@id': file,
                  'label': make_label(file),
                  'metadata': get_gt_metadata(f'{GT_DIR}/{file}')}}
            gt.append(d)

    url = 'http://localhost:8084/api/gt'

    for data in gt:
        r = requests.post(url, json=data, timeout=10)
        print(f"{r.status_code}: {data['gt_workspace']['label']}")


if __name__ == '__main__':
    print('Adding GT data to the Quiver database.')
    post_gt()
    print('Finished process.')
