# syntax = docker/dockerfile:experimental
FROM pytorch/torchserve:0.3.0-cpu as base

USER root

FROM base as reqs
RUN apt-get update -y
RUN apt install libgl1-mesa-glx -y
RUN apt-get install 'ffmpeg' 'libsm6' 'libxext6'  -y
COPY gcp/inference/requirements.txt requirements.txt
RUN pip3 install --upgrade pip
RUN pip install -r requirements.txt

FROM reqs as build-torchserve
COPY gcp/inference/handler.py /home/model-server
COPY model_weights/*.pt /home/model-server
COPY street2sat_utils /home/model-server/street2sat_utils

WORKDIR /home/model-server

RUN torch-model-archiver \
    --model-name street2sat \
    --version 1.0 \
    --serialized-file best.torchscript.pt \
    --handler handler.py \
    --export-path=model-store

ENV LABEL_IMG_PERCENT=1.0
ENV DEST_BUCKET_NAME="street2sat-model-predictions"
CMD ["torchserve", "--start", "--ncs", "--model-store", "model-store", \
       "--models", "street2sat=street2sat.mar"]


