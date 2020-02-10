# pipeline

## Usage

Suppose that the input file is "data.gfa".

```
$ docker build -t pipeline .
$ docker run -ti --rm --publish=3000:3000 --volume=`pwd`:/usr/src/app/data pipeline data/data.gfa
```

Access to http://localhost:3000/

