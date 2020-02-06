FROM quay.io/biocontainers/odgi:0.2--py37h8b12597_0 as build

FROM node:alpine

WORKDIR /usr/src/app

RUN apk add git python3 python3-dev

RUN git clone https://github.com/graph-genome/component_segmentation

RUN git clone https://github.com/graph-genome/schematize

COPY --from=build /usr/local/bin/odgi /usr/local/bin/ 

RUN pip3 install --upgrade pip && pip3 install -r component_segmentation/requirements.txt

ADD . .

EXPOSE 3000

ENTRYPOINT /usr/src/app/pipeline.sh
