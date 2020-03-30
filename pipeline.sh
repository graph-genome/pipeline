#!/bin/bash

set -e # abort on error

function usage
{
  echo "usage: pipeline.sh GFA_FILE [-b 00 -e 01 -s bSnSnS -w 1000 -t 12 -h]"
  echo "   ";
  echo "  -b | --begin   : The start bin";
  echo "  -e | --end     : The end bin";
  echo "  -s | --sort    : Sort option on odgi";
  echo "  -w | --width   : Bin width on odgi";
  echo "  -t | --threads : Threads on odgi";
  echo "  -h | --help    : This message";
}

function parse_args
{
  # positional args
  args=()

  # named args
  while [ "$1" != "" ]; do
      case "$1" in
          -b | --begin )                begin_bin="$2";          shift;;
          -e | --end )                  end_bin="$2";            shift;;
          -s | --sort )                 sort_opt="$2";           shift;;
          -w | --width )                width_opt="$2";          shift;;
          -t | --threads )              threads_opt="$2";        shift;;
          -h | --help )                 usage;                   exit;; # quit and show usage
          * )                           args+=("$1")             # if no match, add it to the positional args
      esac
      shift # move to next kv pair
  done

  # restore positional args
  set -- "${args[@]}"

  # set positionals to vars
  gfa_path="${args[0]}"

  # validate required args
  if [[ -z "$gfa_path" ]]; then
      echo "Invalid arguments"
      usage
      exit;
  fi
}

parse_args "$@"

ODGI=odgi
GFA=$gfa_path 
OG=${GFA%.gfa}.og
SOG=${GFA%.gfa}.sorted.og
THREADS=${threads_opt:-12}
w=${width_opt:-1000}
STARTCHUNK=${begin_bin:-00}
ENDCHUNK=${end_bin:-01}
SORT=${sort_opt:-bSnSnS}

echo "### bin-width: ${w}"
echo "### chunk: ${STARTCHUNK}--${ENDCHUNK}"
echo "### sort-option: ${SORT}"

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
--pipeline="$SORT" \
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
python3 matrixcomponent/segmentation.py -j ../${BIN} --cells-per-file $((ENDCHUNK+1)) -o ../${SEGPREF} \
> ../${SEGPREF}.log 2>&1
cd ..

NOF=$(ls ${GFA%.gfa}.w${w}/*.schematic.json | wc -l)

if [ $NOF -lt 1 ]; then
  echo "### component segmentation failed"
  exit 255
fi

## Run Schematize
echo "### Schematize"
#SCHEMATICBIN=${GFA%.gfa}.w${w}/chunk0000_bin${w}.schematic.json
SCHEMATIC=${GFA%.gfa}.w${w}
if [ ! -d "Schematize" ]; then
  git clone --depth 1 https://github.com/graph-genome/Schematize
  cd Schematize
  npm install
  cd ..
fi
cp -r ${SCHEMATIC} Schematize/public/test_data
BASENAME=`basename ${SCHEMATIC}`
#sed -E "s|run1.B1phi1.i1.seqwish.w100.schematic.json|${BASENAME}|g" Schematize/src/PangenomeSchematic.js > Schematize/src/PangenomeSchematic2.js
sed -E "s|Athaliana_12_individuals_w100000/chunk00_bin100000.schematic.json|${BASENAME}/chunk${STARTCHUNK}_bin${w}.schematic.json|g" Schematize/src/ViewportInputsStore.js > Schematize/src/ViewportInputsStore3.js 
sed -E "s|Athaliana_12_individuals_w100000/chunk01_bin100000.schematic.json|${BASENAME}/chunk${ENDCHUNK}_bin${w}.schematic.json|g" Schematize/src/ViewportInputsStore3.js > Schematize/src/ViewportInputsStore4.js 
sed -E "s|Athaliana_12_individuals_w100000|${BASENAME}|g" Schematize/src/ViewportInputsStore4.js > Schematize/src/ViewportInputsStore2.js
mv Schematize/src/ViewportInputsStore2.js Schematize/src/ViewportInputsStore.js
cd Schematize
npm run-script build
npm run start 
