#!/bin/bash

ODGI=odgi
GFA=$1 
OG=${GFA%.gfa}.og
SOG=${GFA%.gfa}.sorted.og
THREADS=12
w=${2:-1000}

echo "### bin-width: ${w}"

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

if [ ! -f $OG ]; then
  echo "### odgi build failed"
  exit 255
fi

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

if [ ! -f $SOG ]; then
  echo "### odgi sort failed"
  exit 255
fi

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

if [ ! -f $BIN ]; then
  echo "### odgi bin failed"
  exit 255
fi

## Run component segmentation
echo "### component segmentation"
SEGPREF=${GFA%.gfa}.seg
if [ ! -d "${GFA%.gfa}.seg" ]; then
  mkdir ${GFA%.gfa}.seg
fi
if [ ! -d "component_segmentation" ]; then
  git clone --depth 1 https://github.com/graph-genome/component_segmentation
fi
cd component_segmentation
export PYTHONPATH=`pwd`:PYTHONPATH 
/usr/bin/time -v -o ../${SEGPREF}.time \
ionice -c2 -n7 \
python3 matrixcomponent/segmentation.py -j ../${BIN} -b ${w} -o ../${SEGPREF} \
> ../${SEGPREF}.log 2>&1
cd ..

NOF=$(ls "{GFA%.gfa}.w${w}/*.schematic.json" | wc -l)

if [ $NOF -lt 1 ]; then
  echo "### component segmentation failed"
  exit 255
fi

## Run Schematize
echo "### Schematize"
SCHEMATICBIN=${GFA%.gfa}.w${w}/chunk0000_bin${w}.schematic.json
if [ ! -d "Schematize" ]; then
  git clone --depth 1 https://github.com/graph-genome/Schematize
  npm install
fi
cp ${SCHEMATICBIN} Schematize/src/data/
BASENAME=`basename ${SCHEMATICBIN}`
sed -E "s|run1.B1phi1.i1.seqwish.w100.schematic.json|${BASENAME}|g" Schematize/src/PangenomeSchematic.js > Schematize/src/PangenomeSchematic2.js
mv Schematize/src/PangenomeSchematic2.js Schematize/src/PangenomeSchematic.js
cd Schematize
npm run-script build
npm run start 
