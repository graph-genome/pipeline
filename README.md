# pipeline

## Usage

Suppose that the input file is "data.gfa".

```bash
$ git clone https://github.com/graph-genome/pipeline
$ cd pipeline
$ cp /pass/to/your/data.gfa .
$ docker build -t pipeline .
$ docker run -ti --rm --publish=3000:3000 --volume=`pwd`:/usr/src/app/data pipeline data/data.gfa
$ docker run -ti --rm --publish=3000:3000 --volume=`pwd`:/usr/src/app/data pipeline data/data.gfa 10000 
  # You can change bin width.
```

Access to http://localhost:3000/.

