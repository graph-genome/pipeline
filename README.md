# pipeline

A pipeline combining [odgi](https://github.com/vgteam/odgi) - [component_segmentation](https://github.com/graph-genome/component_segmentation) - [Schematize](https://github.com/graph-genome/Schematize) on Docker image or CWL

## Installation

Docker is needed before running.

```bash
git clone https://github.com/graph-genome/pipeline
cd pipeline
docker build -t pipeline .
```

## Usage

### Running on CWL on example data

```bash
pip install arvados-cwl-runner

cwltool --cachedir $PWD/cache --parallel graph-genome-previz.cwl example_plain.yml
# for local execution

# or
arvados-cwl-runner graph-genome-previz.cwl example_arvados.yml
```

### Running on Docker

Suppose that the input file is "data.gfa".

```bash
cp /pass/to/your/data.gfa .
docker run -ti --rm --publish=3000:3000 --volume=`pwd`:/usr/src/app/data pipeline data/data.gfa
docker run -ti --rm --publish=3000:3000 --volume=`pwd`:/usr/src/app/data pipeline data/data.gfa -w 10000 
  # With -w argument you can change the bin width.
docker run -ti --rm --publish=3000:3000 --volume=`pwd`:/usr/src/app/data pipeline data/data.gfa -w 10000 -s Sn
  # With -s argument you can change the sort option.
```

Access to http://localhost:3000/. The production build of Schematize is running.



## Running PathIndex Server

Pathindex server works on the same container of Schematize at port 3010. Users need to specify the host of the server.

```bash
docker run -ti --rm \
  --publish=3000:3000 \ # For Schematize server 
  --publish=3010:3010 \ # For odgi server (*)
  --volume=`pwd`:/usr/src/app/data pipeline data/data.gfa -w 10000 -s Sn \
  --port 3010 \ # The host's port to expose the odgi server, the same as the host port of (*).
  --host localhost # The host name to expose the odgi server.
```

If you change the server to `example.com:3020` to expose odgi server, then

```bash
docker run -ti --rm \
  --publish=3000:3000 \ # For Schematize server
  --publish=3020:3010 \ # For odgi server (*)
  --volume=`pwd`:/usr/src/app/data pipeline data/data.gfa -w 10000 -s Sn \
  --port 3020 \ # The host's port to expose the odgi server, the same as the host port of (*). 
  --host "example.com" # The host name to expose the odgi server.
```

## Customization

You can change the options on odgi / Schematize.

* gfa name (first argument, mandatory)
* `-w`: the bin width on `odgi` (optional, default: `1000`)
* `-s`: the sort option on `odgi sort` (optional, default: `bSnSnS`)
* `-t`: the threads option on `odgi` (optional, default: `12`)
* `-c`: the cells-per-file option on `component_segmentation` (optional)
* `-i`: the host of `odgi index` (optional, default: `localhost`)

The full list of the argument is as follows:

```bash
docker run -ti --rm --publish=3000:3000 --volume=`pwd`:/usr/src/app/data pipeline -h
```

## Support Development

```bash
git clone https://github.com/graph-genome/component_segmentation # For debugging component_segmentation
git clone https://github.com/graph-genome/Schematize # For debugging Schematize
docker run -d --publish=3000:3000 --publish=3010:3010 --volume=`pwd`:/usr/src/app/data --volume=`pwd`/Schematize:/usr/src/app/Schematize --volume=`pwd`/component_segmentation:/usr/src/app/component_segmentation pipeline data/data.gfa -w 1000 -s s -c 10000
```

Then, the pipeline is running through cloned component_segmentation and Schematize. Docker container is failed, but the output json file is stored on Schematize directory. Therefore just run `yarn start` on `Schematize` directory works.
