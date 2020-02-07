# pipeline

## Usage

Suppose that the input file is "data.gfa".

```
$ docker build -t pipeline .
$ docker run -p 3000:3000 pipeline data.gfa 
```

Access to http://localhost:3000/

