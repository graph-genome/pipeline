# pipeline

A pipeline combining [odgi](https://github.com/vgteam/odgi) - [component_segmentation](https://github.com/graph-genome/component_segmentation) - [Schematize](https://github.com/graph-genome/Schematize) on Docker image

## Installation

Docker is needed before running.

```bash
git clone https://github.com/graph-genome/pipeline
cd pipeline
docker build -t pipeline .
```

## Usage

Suppose that the input file is "data.gfa".

```bash
cp /pass/to/your/data.gfa .
docker run -ti --rm --publish=3000:3000 --volume=`pwd`:/usr/src/app/data pipeline data/data.gfa
docker run -ti --rm --publish=3000:3000 --volume=`pwd`:/usr/src/app/data pipeline data/data.gfa -w 10000 
  # With -w argument you can change the bin width.
docker run -ti --rm --publish=3000:3000 --volume=`pwd`:/usr/src/app/data pipeline data/data.gfa -w 10000 -b 00 -e 01 
  # With -b end -e argument you can change the start and end chunk.
docker run -ti --rm --publish=3000:3000 --volume=`pwd`:/usr/src/app/data pipeline data/data.gfa -w 10000 -b 00 -e 01 -s S
  # With -s argument you can change the sort option.
```

Access to http://localhost:3000/.

## Customization

You can change the options on odgi / Schematize.

* gfa name (first argument, mandatory)
* `-w`: the bin width on `odgi` (optional, default: `1000`)
* `-b` and `-e`: the start and end chunk on `Schematize` (optional, default: `00--01`)
* `-s`: the sort option on `odgi sort` (optional, default: `bSnSnS`)

The full list of the argment is as follows:

```bash
docker run -ti --rm --publish=3000:3000 --volume=`pwd`:/usr/src/app/data pipeline -h
```


