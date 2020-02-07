FROM node:alpine

WORKDIR /usr/src/app

RUN apk add git python3 python3-dev bash cmake make g++

RUN git clone --recursive https://github.com/vgteam/odgi.git

RUN cd odgi && cmake -DBUILD_STATIC=1 -H. -Bbuild && cmake --build build -- -j 3

RUN pip3 install --upgrade pip && pip3 install -r component_segmentation/requirements.txt

ENV PATH $PATH:/usr/src/app/

ADD . .

EXPOSE 3000

ENTRYPOINT pipeline.sh
