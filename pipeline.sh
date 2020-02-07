#!/bin/bash

ODGI=odgi
GFA=$1 
OG=${GFA%.gfa}.og
SOG=${GFA%.gfa}.sorted.og
THREADS=7

## Build the sparse matrix form of the gfa graph
echo "### odgi build"
BLDPREF=pipeline.sh_01_build
/usr/bin/time -v -o ${BLDPREF}.time \
ionice -c2 -n7 \
$ODGI build \
--progress \
--gfa=$GFA \
--out=$OG \
> ${BLDPREF}.log 2>&1
#--sort \

## Sort paths by 1D sorting
echo "### odgi sort"
SRTPREF=pipeline.sh_02_sort
/usr/bin/time -v -o ${SRTPREF}.time \
ionice -c2 -n7 \
$ODGI sort \
--pipeline="bSnSnS" \
--sgd-use-paths \
--paths-max \
--progress \
--idx=$OG \
--out=$SOG \
--threads="$THREADS"\
> ${SRTPREF}.log 2>&1

##
echo "### odgi bin"
w=10000
BIN=${GFA%.gfa}.w${w}.json
BINPREF=pipeline.sh_04_bin_w${w}
SRTPREF=pipeline.sh_03_bin
/usr/bin/time -v -o ${SRTPREF}.time \
ionice -c2 -n7 \
$ODGI bin \
--json \
--idx=$SOG \
--bin-width=${w} \
1> $BIN \
2> ${BINPREF}.log &

##
echo "### component segmentation"
SEGPREF=${GFA%.gfa}.seg
mkdir ${GFA%.gfa}.seg
git clone https://github.com/graph-genome/component_segmentation
cd component_segmentation
PYTHONPATH=`pwd`:PYTHONPATH python3 matrixcomponent/segmentation.py -j ../${BIN} -o ../${SEGPREF}
cd ..

## Run Schematize
echo "### Run Schematize"
SCHEMATICBIN=${GFA%.gfa}.w${w}.schematic.json
git clone https://github.com/graph-genome/Schematize
cp ${SCHEMATICBIN} Schematize/src/data/
sed -ie "s/run1.B1phi1.i1.seqwish.w100.schematic.json/${SCHEMATICBIN}/g" Schematize/src/PangenomeSchematic.js
cd Schematize
npm install
npm build
npm run start 
