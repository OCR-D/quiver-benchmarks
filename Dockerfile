FROM ocrd/all:2023-03-26

WORKDIR /app

COPY requirements.txt requirements.txt

RUN apt install git
RUN apt install -y jq
RUN apt install -y netcat
RUN apt-get update
RUN apt-get install -y --fix-missing openjdk-11-jre

COPY setup.py setup.py
COPY README.md README.md
COPY scripts scripts
COPY data_srcs data_srcs

RUN git init
RUN git submodule add https://github.com/MehmedGIT/OtoN_Converter submodules/oton
RUN git submodule update --init

RUN cd submodules/oton && \
    pip install .

RUN pip3 install -r requirements.txt
COPY src/benchmarks src
COPY src/cli.py src
COPY src/constants.py src
RUN pip3 install .
RUN nextflow

ENTRYPOINT [ "bash" ]