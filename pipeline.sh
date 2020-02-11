#!/bin/bash

ODGI=odgi
GFA=$1 
OG=${GFA%.gfa}.og
SOG=${GFA%.gfa}.sorted.og
THREADS=12
w=${2:-1000}

## Build the sparse matrix form of the gfa graph
echo "### odgi build"
BLDPREF=${GFA%.gfa}_01_build
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
SRTPREF=${GFA%.gfa}_02_sort
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
BIN=${GFA%.gfa}.w${w}.json
BINPREF=${GFA%.gfa}_04_bin_w${w}
SRTPREF=${GFA%.gfa}_03_bin
/usr/bin/time -v -o ${SRTPREF}.time \
ionice -c2 -n7 \
$ODGI bin \
--json \
--idx=$SOG \
--bin-width=${w} \
1> $BIN \
2> ${BINPREF}.log

## Run component segmentation
echo "### component segmentation"
SEGPREF=${GFA%.gfa}.seg
mkdir ${GFA%.gfa}.seg
git clone --depth 1 https://github.com/graph-genome/component_segmentation
cd component_segmentation
export PYTHONPATH=`pwd`:PYTHONPATH 
/usr/bin/time -v -o ../${SEGPREF}.time \
ionice -c2 -n7 \
python3 matrixcomponent/segmentation.py -j ../${BIN} -o ../${SEGPREF} \
> ../${SEGPREF}.log 2>&1
cd ..

## Run Schematize
echo "### Run Schematize"
SCHEMATICBIN=${GFA%.gfa}.w${w}.schematic.json
git clone --depth 1 https://github.com/graph-genome/Schematize
cp ${SCHEMATICBIN} Schematize/src/data/
sed -ie "s/run1.B1phi1.i1.seqwish.w100.schematic.json/${SCHEMATICBIN}/g" Schematize/src/PangenomeSchematic.js
cd Schematize
npm install
npm build
npm run start 
