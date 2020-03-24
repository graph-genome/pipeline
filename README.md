# pipeline

A pipeline combining odgi - component_segmentation - Schematize on Docker image

## Installation

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
```

Access to http://localhost:3000/.

## Customization


