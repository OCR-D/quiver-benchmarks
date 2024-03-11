FROM docker.io/ocrd/all:maximum

WORKDIR /app

COPY requirements.txt requirements.txt

RUN apt-get install git
RUN apt-get install -y jq
RUN apt-get install -y netcat
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
COPY src src
RUN pip3 install .
RUN nextflow
RUN nextflow plugin install nf-weblog

ENV OCRD_METS_CACHING=0

#ENTRYPOINT [ "bash" ]
CMD [ "bash", "scripts/run_trigger.sh" ]
