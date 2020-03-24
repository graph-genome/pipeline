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
docker run -ti --rm --publish=3000:3000 --volume=`pwd`:/usr/src/app/data pipeline data/data.gfa 10000 
  # With the second argument you can change the bin width.
docker run -ti --rm --publish=3000:3000 --volume=`pwd`:/usr/src/app/data pipeline data/data.gfa 10000 00 01 
  # With the third and fourth argument you can change the start and end chunk.
docker run -ti --rm --publish=3000:3000 --volume=`pwd`:/usr/src/app/data pipeline data/data.gfa 10000 00 01 S
  # With the third and fourth argument you can change the start and end chunk.
```

Access to http://localhost:3000/.

## Customization

You can change the options on odgi / 

* gfa name (first argument, mandatory)
* the bin width on `odgi` (second argument, optional, default:1000)
* the start and end chunk on `Schematize` (third and fourth argument, optional, default: 00-01)
* the sort option on `odgi sort` (fifth argument, optional, default: bSnSnS)

