# QuiVer Benchmarks – Local

"QuiVer Benchmarks – Local" is a tool that helps you decide which OCR-D workflows are most suitable for your data.
It executes preset or custom workflows on [Ground Truth](#getting-ground-truth-into-the-database) and evaluates the result with [`dinglehopper`](https://github.com/qurator-spk/dinglehopper).

This repository holds everything needed to automatically execute different OCR-D workflows on images and evaluate the outcomes.
It creates benchmarks for OCR-D data in a containerized environment.

QuiVer Benchmarks – Local is based on `ocrd/all:maximum` and has all OCR-D processors at hand that a workflow might use.

## Requirements

- Docker >= 23.0.0
- [Docker Compose plugin](https://docs.docker.com/compose/install/linux/#install-using-the-repository)
- make
- python3

To speed up QuiVer Benchmarks – Local you can mount already downloaded text recognition models to `/usr/local/share/ocrd-resources/` in `docker-compose.yml` by adding

```yml
- path/to/your/models:/usr/local/share/ocrd-resources/
```

to the `volumes` section.
Otherwise, the tool will download all `ocrd-tesserocr-recognize` models as well as `ocrd-calamari-recognize qurator-gt4histocr-1.0` on each run.

## General Setup Information

QuiVer Benchmarks – Local consists of several Docker services that are definded in the `docker-compose.yaml`, each with a specific purpose:

- `ocr`: This service executes the OCR-D workflows, evaluates their results and posts all relevant information to the `mongodb` container.
- `mongodb`: The database where information about the Ground Truth data, the workflows and the results of the runs are stored.
- `api`: This service runs a Uvicorn server with a FastAPI application that is responsible for getting data in and out of the database. `ocr` uses it to post data to and `frontend` requests the API the obtain data from the MongoDB. The API is available at `localhost:8084`; its documentation can be viewed at `localhost:8084/docs`.
- `frontend`: A vue.js application where the results of QuiVer Benchmarks – Local can be viewed. The front end is available at `localhost:5173`.

## Usage

### Initial Setup

- clone this repository: `git clone git@github.com:OCR-D/quiver-benchmarks.git`
- switch to the cloned directory: `cd quiver-benchmarks`
- build the image with `make build`

#### Defining Your Own Workflows

Add new OCR-D workflows to the directory `workflows/ocrd_workflows` according to the following conventions:

- OCR workflows have to end with `_ocr.txt`, evaluation workflows with `_eval.txt`. The files will be converted by [OtoN](https://github.com/MehmedGIT/OtoN_Converter) to Nextflow files after the container has started.
- workflows have to be TXT files
- all workflows have to use [`ocrd process`](https://ocr-d.de/en/user_guide#ocrd-process)

Since the whole `workflows` directory is mounted as a volume, new workflows will be considered without rebuilding the Docker image.

To remove a workflow from QuiVer Benchmarks – Local just delete the respective *.txt file.

#### Getting Ground Truth into the Database

You can either use OCR-D's default Ground Truth, your own or a mix of both.

##### Use the Default Ground Truth

To load the default Ground Truth, simply run `make start` and `make prepare-default-gt`.

##### Use Custom Ground Truth

TODO

#### Getting Your Workflows into the Database

TODO

### Running QuiVer Benchmarks – Local

After you have completed the [inital setup](#initial-setup), you can start the actual OCR process and its evaluation via `make run`. (Run `make start` if your container setup is not up yet.)

Logging for the process is available in the `logs` directory. The results of the runs are available in the front end (`localhost:5173`) or via the API in JSON (`localhost:8084/api/runs`).

## Benchmarks Considered

The relevant benchmarks gathered by QuiVer Benchmarks are defined in [OCR-D's Quality Assurance specification](https://ocr-d.de/en/spec/ocrd_eval) and comprise

- CER (per page and document wide), incl.
  - median
  - minimum and maximum CER
  - standard deviation
- WER (per page and document wide)
- CPU time
- wall time
- processed pages per minute

## OCR-D Default Ground Truth

The OCR-D Default Ground Truth consists of the following repositories:

- [https://github.com/tboenig/16_frak_simple](https://github.com/tboenig/16_frak_simple)
- [https://github.com/tboenig/17_frak_simple](https://github.com/tboenig/17_frak_simple)
- [https://github.com/tboenig/17_frak_complex](https://github.com/tboenig/17_frak_complex)
- [https://github.com/tboenig/18_frak_simple](https://github.com/tboenig/18_frak_simple)
- [https://github.com/tboenig/18_frak_complex](https://github.com/tboenig/18_frak_complex)
- [https://github.com/tboenig/19_frak_simple](https://github.com/tboenig/19_frak_simple)
- [https://github.com/tboenig/16_ant_simple](https://github.com/tboenig/16_ant_simple)
- [https://github.com/tboenig/16_ant_complex](https://github.com/tboenig/16_ant_complex)
- [https://github.com/tboenig/18_ant_simple](https://github.com/tboenig/18_ant_simple)
- [https://github.com/tboenig/19_ant_simple](https://github.com/tboenig/19_ant_simple)
- [https://github.com/tboenig/17_fontmix_simple](https://github.com/tboenig/17_fontmix_simple)
- [https://github.com/tboenig/18_fontmix_complex](https://github.com/tboenig/18_fontmix_complex)
- [Reichsanzeiger GT](https://github.com/UB-Mannheim/reichsanzeiger-gt) with many ads
- [Reichsanzeiger GT](https://github.com/UB-Mannheim/reichsanzeiger-gt) with many tables
- [Reichsanzeiger GT](https://github.com/UB-Mannheim/reichsanzeiger-gt) title pages only
- [Reichsanzeiger GT](https://github.com/UB-Mannheim/reichsanzeiger-gt) random selection of pages

A detailed list of images used for the Reichsanzeiger GT sets can be found in the `data_src` directory.

## License

See [LICENSE](LICENSE)
