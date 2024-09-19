FROM ocrd/all:maximum

WORKDIR /app

COPY . /app

RUN apt-get install -y git jq netcat && apt-get update && apt-get install -y --fix-missing openjdk-11-jre && \
    git init &&  \
    git submodule add https://github.com/mweidling/OtoN_Converter submodules/oton && \
    git submodule update --init && \
    cd submodules/oton && \
    pip install . && \
    cd /app && \
    pip3 install -r requirements.txt && pip3 install . && \
    nextflow

ENV OCRD_METS_CACHING=0

ENTRYPOINT [ "bash" ]
#CMD [ "bash", "scripts/run_trigger.sh" ]
