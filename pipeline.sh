#!/bin/bash

set -e # abort on error

function usage
{
  echo "usage: pipeline.sh GFA_FILE [-b 00 -e 01 -s bSnSnS -w 1000 -t 12 -h]"
  echo "   ";
# echo "  -b | --begin          : The start bin";
# echo "  -e | --end            : The end bin";
  echo "  -s | --sort           : Sort option on odgi";
  echo "  -w | --width          : Bin width on odgi";
  echo "  -c | --cells-per-file : Cells per file on component_segmentation";
  echo "  -t | --threads        : Threads on odgi";
  echo "  -p | --port           : Pathindex port";
  echo "  -i | --host           : Pathindex host";
  echo "  -h | --help           : This message";
}

function parse_args
{
  # positional args
  args=()

  # named args
  while [ "$1" != "" ]; do
      case "$1" in
#         -b | --begin )                begin_bin="$2";          shift;;
#         -e | --end )                  end_bin="$2";            shift;;
          -s | --sort )                 sort_opt="$2";           shift;;
          -w | --width )                width_opt="$2";          shift;;
          -c | --cells-per-file )       cpf="$2";                shift;;
          -t | --threads )              threads_opt="$2";        shift;;
          -p | --port )                 port="$2";               shift;;
          -i | --host )                 host="$2";               shift;;
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
XP=${GFA%.gfa}.og.xp
PORT=${port:-3010}
THREADS=${threads_opt:-12}
w=${width_opt:-1000}
#STARTCHUNK=${begin_bin:-00}
#ENDCHUNK=${end_bin:-01}
CPF=${cpf:-${ENDCHUNK}}
SORT=${sort_opt:-bSnSnS}
HOST=${host:-localhost}

echo "### bin-width: ${w}"
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

## Create path index
echo "### odgi pathindex"
BLDPREF=${GFA%.gfa}_05_pathindex
/usr/bin/time -v -o ${BLDPREF}.time \
ionice -c2 -n7 \
$ODGI pathindex \
--idx=$OG \
--out=$XP \
> ${BLDPREF}.log 2>&1

if [ ! -f $XP ]; then
  echo "### odgi pathindex failed"
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
python3 segmentation.py -j ../${BIN} --cells-per-file ${CPF} -o ../${SEGPREF} \
> ../${SEGPREF}.log 2>&1
cd ..

NOF=$(ls ${GFA%.gfa}.seg/*.schematic.json | wc -l)

if [ $NOF -lt 1 ]; then
  echo "### component segmentation failed"
  exit 255
fi

## Run PathIndex Server
echo "### PathIndex Server"

$ODGI server -i $XP -p 3010 -a "0.0.0.0" &

## Run Schematize
echo "### Schematize"
SCHEMATIC=${GFA%.gfa}.seg
if [ ! -d "Schematize" ]; then
  git clone --depth 1 https://github.com/graph-genome/Schematize
  cd Schematize
  npm install
  cd ..
fi
cp -r ${SCHEMATIC} Schematize/public/test_data
STARTCHUNK=`jq -r .files[0].file ${SCHEMATIC}/bin2file.json`
ENDCHUNK=`jq -r .files[-1].file ${SCHEMATIC}/bin2file.json`
BASENAME=`basename ${SCHEMATIC}`
sed -E "s|run1.B1phi1.i1.seqwish.w100/chunk0_bin100.schematic.json|${BASENAME}/${STARTCHUNK}|g" Schematize/src/ViewportInputsStore.js > Schematize/src/ViewportInputsStore3.js 
sed -E "s|run1.B1phi1.i1.seqwish.w100/chunk1_bin100.schematic.json|${BASENAME}/${ENDCHUNK}|g" Schematize/src/ViewportInputsStore3.js > Schematize/src/ViewportInputsStore4.js 
sed -E "s|run1.B1phi1.i1.seqwish.w100|${BASENAME}|g" Schematize/src/ViewportInputsStore4.js > Schematize/src/ViewportInputsStore2.js
sed -E "s|193.196.29.24:3010|${HOST}:${PORT}|g" Schematize/src/ViewportInputsStore2.js > Schematize/src/ViewportInputsStore1.js
mv Schematize/src/ViewportInputsStore1.js Schematize/src/ViewportInputsStore.js
cd Schematize
npm run-script build
cd public
python -m http.server 3000
