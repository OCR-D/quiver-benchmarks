# QuiVer Benchmarks

This repository holds everything you need for automatically executing different OCR-D workflows on images and evaluating the outcomes.
It creates benchmarks for (your) OCR-D data in a containerized environment.
You can run QuiVer Benchmarks either locally on your machine or in an automized workflow, e.g. in a CI/CD environment.

QuiVer Benchmarks is based on `ocrd/all:maximum` and has all OCR-D processors at hand that a workflow might use.

## Prerequisites

- Docker >= 23.0.0

To speed up QuiVer Benchmarks you can mount already downloaded text recognition models to `/usr/local/share/ocrd-resources/` in [`docker-compose.yml`]().
Otherwise the tool will download the models on each run.

## Usage

- clone this repository
- [customize](#custom-workflows-and-data) QuiVer Benchmarks according to your needs
- run `docker compose build && docker compose up`
- the benchmarks and the evaluation results will be available in `data/`

## Benchmarks Considered

The relevant benchmarks gathed by QuiVer Benchmarks are defined in [OCR-D's Quality Assurance specification](https://ocr-d.de/en/spec/eval) and comprise

- CER (per page and document wide), incl.
  - median
  - minimum and maximum CER
  - standard deviation
- WER (per page and document wide)
- CPU time
- wall time
- processed pages per minute

## Custom Workflows and Data

The default behaviour of QuiVer Benchmarks is to collect OCR-D's sample Ground Truth workspaces (currently stored in [quiver-data](https://github.com/OCR-D/quiver-data)), executing the [recommended standard workflows](https://ocr-d.de/en/workflows#recommendations) on these and obtaining the relevant [benchmarks](#benchmarks-considered) for each workflow.

You can, however, customize QuiVer Benchmarks to run your own workflows on the sample workspaces or your own OCR-D workspaces.

### Adding New OCR-D Workflows

Add new OCR-D workflows to the directory `workflows/ocrd_worflows` according to the following conventions:

- OCR workflows have to end with `_ocr.txt`, evaluation workflows with `_eval.txt`. The files will be converted by OtoN to Nextflow files after the container has started.
- workflows have to be TXT files
- all workflows have to use [`ocrd process`](https://ocr-d.de/en/user_guide#ocrd-process)

Since the `workflows` directory is mounted to the container spun up by `docker compose up` it is not necessary to rebuild the Docker image.

### Removing OCR-D Workflows

Delete the respective TXT files from `workflows/ocrd_workflows`.

### Using Custom Data

+++ TODO +++

## Development

## Outlook

## License

See [LICENSE](LICENSE)
