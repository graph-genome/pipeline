FROM python:slim

WORKDIR /usr/src/app

RUN apt-get update && apt-get install -y git nodejs npm bash cmake make g++ time 

RUN git clone --recursive https://github.com/vgteam/odgi.git

RUN cd odgi && cmake -H. -Bbuild && cmake --build build -- -j 3 # cmake -DBUILD_STATIC=1 -H. -Bbuild && cmake --build build -- -j 3

RUN git clone --depth=1 https://github.com/graph-genome/component_segmentation

RUN pip3 install -r component_segmentation/requirements.txt

ENV PATH $PATH:/usr/src/app/:/usr/src/app/odgi/bin/

RUN git clone --depth=1 https://github.com/graph-genome/Schematize

RUN cd Schematize && npm install

ADD . .

EXPOSE 3000

ENTRYPOINT ["pipeline.sh"]
