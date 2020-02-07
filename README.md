# pipeline

## Usage

Suppose that the input file is "data.gfa".

```
$ docker build -t pipeline .
$ docker run --rm --publish=3000:3000 --volume=`pwd`:/usr/src/app/data pipeline data/DATA.gfa
```

Access to http://localhost:3000/

