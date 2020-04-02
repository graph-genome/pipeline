FROM python:slim

WORKDIR /usr/src/app

RUN apt-get update && apt-get install -y git curl software-properties-common bash cmake make g++ time jq python3-distutils python3-dev

RUN curl -sL https://deb.nodesource.com/setup_13.x | bash -

RUN apt-get install -y nodejs

RUN git clone --recursive https://github.com/vgteam/odgi.git

RUN cd odgi && cmake -H. -Bbuild && cmake --build build -- -j 3

RUN git clone --depth=1 https://github.com/graph-genome/component_segmentation

RUN pip3 install -r component_segmentation/requirements.txt

ENV PATH $PATH:/usr/src/app/:/usr/src/app/odgi/bin/

RUN git clone --depth=1 https://github.com/graph-genome/Schematize

RUN cd Schematize && npm install

RUN npm install -g serve

ADD . .

EXPOSE 3000

EXPOSE 3010

ENTRYPOINT ["pipeline.sh"]
