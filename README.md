# QuiVer Benchmarks

This repository holds everything you need to automatically execute different OCR-D workflows on images and evaluate the outcomes.
It creates benchmarks for (your) OCR-D data in a containerized environment.
You can run QuiVer Benchmarks either locally on your machine or in an automated workflow, e.g. in a CI/CD environment.

QuiVer Benchmarks is based on `ocrd/all:maximum` and has all OCR-D processors at hand that a workflow might use.

## Requirements

- Docker >= 23.0.0
- [Docker Compose plugin](https://docs.docker.com/compose/install/linux/#install-using-the-repository)

To speed up QuiVer Benchmarks you can mount already downloaded text recognition models to `/usr/local/share/ocrd-resources/` in `docker compose.yml` by adding

```yml
- path/to/your/models:/usr/local/share/ocrd-resources/
```

to the `volumes` section.
Otherwise, the tool will download all `ocrd-tesserocr-recognize` models as well as `ocrd-calamari-recognize qurator-gt4histocr-1.0` on each run.

## Usage

- clone this repository
- (optional) [customize](#custom-workflows-and-data) QuiVer Benchmarks according to your needs
- run `docker compose up --build`
- the benchmarks and the evaluation results will be available at `data/workflows.json` on your host system

## Benchmarks Considered

The relevant benchmarks gathered by QuiVer Benchmarks are defined in [OCR-D's Quality Assurance specification](https://ocr-d.de/en/spec/eval) and comprise

- CER (per page and document wide), incl.
  - median
  - minimum and maximum CER
  - standard deviation
- WER (per page and document wide)
- CPU time
- wall time
- processed pages per minute

## Custom Workflows and Data

The default behaviour of QuiVer Benchmarks is to collect OCR-D's sample Ground Truth workspaces (currently stored in [quiver-data](https://github.com/OCR-D/quiver-data)), execute the [recommended standard workflows](https://ocr-d.de/en/workflows#recommendations) on these and obtain the relevant [benchmarks](#benchmarks-considered) for each workflow.

You can, however, customize QuiVer Benchmarks to run your own workflows on the sample workspaces or your own OCR-D workspaces.

### Adding New OCR-D Workflows

Add new OCR-D workflows to the directory `workflows/ocrd_worflows` according to the following conventions:

- OCR workflows have to end with `_ocr.txt`, evaluation workflows with `_eval.txt`. The files will be converted by [OtoN](https://github.com/MehmedGIT/OtoN_Converter) to Nextflow files after the container has started.
- workflows have to be TXT files
- all workflows have to use [`ocrd process`](https://ocr-d.de/en/user_guide#ocrd-process)

You can then either rebuild the Docker image via `docker compose build` or mount the directory to the container via

```yml
- ./workflows/ocrd_workflows:/app/workflows/ocrd_workflows
```

in the `volumes` section and spin up a new run with `docker compose up`.

### Removing OCR-D Workflows

Delete the respective TXT files from `workflows/ocrd_workflows` and either rebuild the image or mount the directory as volume as described [above](#adding-new-ocr-d-workflows).

### Using Custom Data

+++ TODO +++

## Development

## Outlook

## License

See [LICENSE](LICENSE)
