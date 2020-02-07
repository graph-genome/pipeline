#!/bin/bash

ODGI=odgi
GFA=$1 
OG=${GFA%.gfa}.og
SOG=${GFA%.gfa}.sorted.og
THREADS=7

## Build the sparse matrix form of the gfa graph
echo "### odgi build"
BLDPREF=${0%.sh}_01_build
/usr/bin/time -v -o ${BLDPREF}.time \
ionice -c2 -n${THREADS} \
$ODGI build \
--progress \
--gfa=$GFA \
--out=$OG \
> ${BLDPREF}.log 2>&1
#--sort \

## Sort paths by 1D sorting
echo "### odgi sort"
SRTPREF=${0%.sh}_02_sort
/usr/bin/time -v -o ${SRTPREF}.time \
ionice -c2 -n${THREADS} \
$ODGI sort \
--pipeline="bSnSnS" \
--sgd-use-paths \
--paths-max \
--progress \
--idx=$OG \
--out=$SOG \
--threads="20"\
> ${SRTPREF}.log 2>&1

##
echo "### odgi bin"
w=10000
BIN=${GFA%.gfa}.w${w}.json
BINPREF=${0%.sh}_04_bin_w${w}
SRTPREF=${0%.sh}_03_bin
/usr/bin/time -v -o ${SRTPREF}.time \
ionice -c2 -n${THREADS} \
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
python3 component_segmentation/matrixcomponent/segmentation.py -j ${BIN} -o ${SEGPREF}


## Run Schematize
echo "### Run Schematize"
SCHEMATICBIN=${GFA%.gfa}.w${w}.schematic.json
git clone https://github.com/graph-genome/Schematize
cp ${SCHEMATICBIN} Schematize/src/data/
sed -e "s/run1.B1phi1.i1.seqwish.w100.schematic.json/${SCHEMATICBIN}/g" Schematize/src/PangenomeSchematic.js > Schematize/src/PangenomeSchematic.js
cd Schematize
npm install
npm run start 
