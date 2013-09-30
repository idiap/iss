#!/bin/zsh (for editor mode; not executable)
#
# Copyright 2010 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, October 2010
#   David Imseng, November 2010
#

#
# Config file for HTS scripts
#
# The general syntax is
#
#  var=${VAR:-default}
#
# which sets shell variable $var to the environment variable $VAR if
# set, and the default value otherwise.  In the case where $var is an
# array, you can say:
#
#  var=${VAR:-"default1 default2"}; var=($=var)
#
# where the ${=var} construct splits the string on whitespace like
# some other shells do.  A bit messy though.
#
# Some naming conventions:
#
#  train-list.txt    List of training files
#  decode-list.txt   List of decoding files
#  ...etc.
#
#  dir/mono-list.txt Phone list
#  dir/hmm-list.txt  Model list
#  dir/mmf.txt       Models
#  dir/mmf-1.bin     Mixture models (during training; eval is txt)
#  dir/stats.txt     Occupation statistics
#  dir/trees.txt     Decision trees
#
# so in general you only need to know the model directory.
#
echo script: ${this:-undefined}
echo config: $0

# Logging
logDir=log
mkdir -p $logDir

# Global sort of stuff
binDir=$(dirname $0)
baseDir=$(dirname $binDir)
libDir=$baseDir/lib
fpath=( $libDir/zsh $fpath )
nJobs=${N_JOBS:-20}
nice=${NICE:-10}
wordMLF=${WORD_MLF:-word.mlf}
useSP=${USE_SP:-true}

# Database
# Typically you run in a subdirectory of $dbaseRoot
dbaseRoot=${DBASE_ROOT:-..}
dbaseDir=$dbaseRoot/dbase
audioDir=$dbaseRoot/audio
featsDir=$dbaseRoot/feats

# Dictionares
sampaMap=${SAMPA_MAP:-}
flatDict=${FLAT_DICT:-flat-dict.txt}
mainDict=${MAIN_DICT:-main-dict.txt}


# HTS
htsOptions=( ${=HTS_OPTIONS:--A} )
htsConfig=${HTS_CONFIG:-main.cnf}
hcopy=${HCOPY:-$(which HCopy)}
hdman=${HDMAN:-$(which HDMan)}
hcompv=${HCOMPV:-$(which HCompV)}
herest=${HEREST:-$(which HERest)}
hinit=${HINIT:-$(which HInit)}
hmgens=${HMGENS:-$(which HMGenS)}
hrest=${HREST:-$(which HRest)}
hhed=${HHED:-$(which HHEd)}
hled=${HLED:-$(which HLEd)}
hvite=${HVITE:-$(which HVite)}
hdecode=${HDECODE:-$(which HDecode)}
hbuild=${HBUILD:-$(which HBuild)}
hresults=${HRESULTS:-$(which HResults)}
hparse=${HPARSE:-$(which HParse)}
hsmmalign=${HSMMALIGN:-$(which HSMMAlign)}
hwarp=${HWARP:-$(which HWarp)}
lnorm=${LNORM:-$(which LNorm)}
hlmcopy=${LNORM:-$(which HLMCopy)}

prune=${=PRUNE:-"500.0 250.0 5000.0"}; prune=($=prune)

# Juicer
juicer=${JUICER:-$(which juicer)}
gramgen=${GRAMGEN:-$(which gramgen)}
lexgen=${LEXGEN:-$(which lexgen)}
cdgen=${CDGEN:-$(which cdgen)}
aux2eps=${AUX2EPS:-$(which aux2eps.pl)}


# Extract
#input
targetKind=${TARGET_KIND:-USER}
featName=${FEAT_NAME:-$targetKind} # merge with targetName?
featExt=${FEAT_EXTENSION:-htk}
audioName=${AUDIO_NAME:-""}
fileList=${FILE_LIST:-file-list}
fileListColumns=$(tail -n 1 $fileList | wc -w)
extract=${EXTRACT:-hcopy}
extracter=${EXTRACTER:-$(which extracter)}
extracterConfig=${EXTRACTER_CONFIG:-/dev/null}
extracterOptions=${EXTRACTER_OPTIONS:-}
hcopyConfig=${HCOPY_CONFIG:-/dev/null}
hcopyConfigTarget=${HCOPY_CONFIG_TARGET:-0}
sspExtracter=${SSP_EXTRACTER:-$(which extracter.py)}
#output
extractList=${EXTRACT_LIST:-extract-list.txt}

# Truncate
#input
truncate=${TRUNCATE:-hcopy}
sourceKind=${SOURCE_KIND:-USER}
sourceName=${SOURCE_NAME:-$sourceKind}
targetName=${TARGET_NAME:-$targetKind}
timingList=${TIMING_LIST:-''}
#output
truncateConfig=${TRUNCATE_CONFIG:-truncate.cfg}
truncateList=${TRUNCATE_LIST:-truncate-list.txt}


# InitTrain
#input
featDimension=${FEAT_DIM:-39}
featDimension2=${FEAT_DIM2:-0}
#output
varFloor=${VAR_FLOOR:-0.01}
protoMMF=proto-mmf.txt
trainList=${TRAIN_LIST_NAME:-train-list.txt}

# Flat start CI Initialisaton
sentBegin="<s>"
sentEnd="</s>"
silModel=sil
flatModelDir=${FLAT_MODEL_DIR:-hmm-flat}
convertDict=$binDir/convertDict.py

#output
flatMLF=${FLAT_MONO_MLF:-flat-mlf.txt}

# Fix silence
spModel=sp
ciSourceDir=${CI_SOURCE_DIR:-$flatModelDir}
ciModelDir=${CI_MODEL_DIR:-hmm-mono}
mainMLF=${MAIN_MONO_MLF:-main-mlf.txt}

# Align
decoder=${DECODER:-HVite}
alignOptions=( ${=ALIGN_OPTIONS:-} )
alignCD=${ALIGN_CD:-0}
alignList=align-list.txt
alignModelDir=${ALIGN_MODEL_DIR:-$ciModelDir}
alignModel=${ALIGN_MODEL_NAME:-mmf.txt}
alignMLF=${ALIGN_MLF:-align-mono.mlf}
alignWordMLF=align-word.mlf

# Reestimate mono
ciMLF=${CI_MLF:-$alignMLF}

# Init tri
cdModelDir=${CD_MODEL_DIR:-hmm-tri}
cdMLF=${CD_MLF:-align-tri.mlf}

# Tie
parsePhoneSet=${PARSE_PHONESET:-$binDir/parse-phoneset.py}
phoneSet=${PHONESET:-CMUbet}
phoneSetCSV=${PHONESET_CSV:-$libDir/phoneset/PhoneSets.csv}
#tiedThreshold=${TIED_THRESHOLD:-0}
tiedMinCluster=${TIED_MIN_CLUSTER:-300}
tiedModelDir=${TIED_MODEL_DIR:-hmm-tied}
tiedTrees=${TIED_TREES:-$tiedModelDir/trees.txt}
fullList=${FULL_LIST:-TRUE}
tieMaxLlkInc=${TIE_MAX_LLK_INC:-0}
tieForceNStates=${TIE_FORCE_NSTATES:--1}
untiedModelDir=${UNTIED_MODEL_DIR:-hmm-untied}

# Mix up
mixModelDir=${MIX_MODEL_DIR:-$tiedModelDir}
mixMLF=${MIX_MLF:-$cdMLF}
mixOrder=${MIX_ORDER:-8}
oldMMF=${OLD_MLF:-}

# Synth full
evalSourceDir=${EVAL_SOURCE_DIR:-$mixModelDir}
evalModelDir=${EVAL_MODEL_DIR:-hmm-eval}
evalOrder=$mixOrder
useMono=${SYNTH_WITH_MONO:-false}

# Generic language model input parameters
lmWordList=${LM_WORD_LIST:-lm-word-list.txt}
lmARPAFile=${LM_ARPA_FILE:-lm-arpa-file.txt}
useLNorm=${USE_LNORM:-false}

# Decoder specific language model parameters
lmDir=${LM_DIR:-htk-lm}

# WFST params
wfst=${WFST:-att}
unknownWord='<UNK>'
lgDir=${WFST_LG_DIR:-wfst-lg}
clgDir=${WFST_CLG_DIR:-wfst-clg}
wfstLM=${WFST_LM:-wfst-lm.txt}
wfstNormLM=${WFST_NORM_LM:-0}
wfstLMScale=${WFST_LM_SCALE:-1.0}
wfstWordPenalty=${WFST_WORD_PENALTY:-0.0}
wfstWords=${WFST_WORDS:-$lgDir/wfst-words.txt}
wfstDict=${WFST_DICT:-$lgDir/wfst-dict.txt}
wfstModelDir=${WFST_MODEL_DIR:-hmm-eval}
wfstOptFinal=${WFST_OPT_FINAL:-0}
wfstLexInSyms=${WFST_LEX_INSYMS:-$lgDir/L.insyms}
wfstGramOutSyms=${WFST_GRAM_OUTSYMS:-$lgDir/G.outsyms}
wfstLG=${WFST_LG:-$lgDir/LG.bfsm}

# Adaptation
nTrees=${N_TREES:-32}
adaptModelDir=${ADAPT_MODEL_DIR:-hmm-eval}
adaptKind=${ADAPT_KIND:-base}
adaptTransKind=${ADAPT_TRANS_KIND:-CMLLR}
adaptTransDir=${ADAPT_TRANS_DIR:-adapt-$adaptKind}
adaptTransExt=${ADAPT_TRANS_EXT:-mllr}
inputTransDir=${INPUT_TRANS_DIR:-""}
inputTransExt=${INPUT_TRANS_EXT:-mllr}
depTransDir=${DEP_TRANS_DIR:-""}
depTransExt=${DEP_TRANS_EXT:-""}
depTransDir2=${DEP_TRANS_DIR_2:-""}
satTransDir=${SAT_TRANS_DIR:-""}
satTransExt=${SAT_TRANS_EXT:-cmllr}
adaptMLF=${ADAPT_MLF:-adapt-tri.mlf}
adaptList=${ADAPT_LIST:-adapt-list.txt}
adaptPattern=${ADAPT_PATTERN:='*.%%%'}
saveSpkrModels=${SAVE_SPKR_MODELS:-""}
useSmap=${USE_SMAP:-""}
smapSigma=${SMAP_SIGMA:-1.0}

# MAP adaptation
mapTau=${MAP_TAU:-10}
hmmMapDir=${HMM_MAP_DIR:-hmm-map}

# Decode
# The default decoder is the same one used for alignment
decodeAcousticModelDir=${DECODE_ACOUSTIC_MODEL_DIR:-$evalModelDir}
decodeLanguageModelDir=${DECODE_LANGUAGE_MODEL_DIR:-$lmDir}
decodeList=${DECODE_LIST:-decode-list.txt}
decodeMLF=${DECODE_MLF:-decode.mlf}
decodeLMScale=${DECODE_LM_SCALE:-1.0}
decodeWordPenalty=${DECODE_WORD_PENALTY:-0.0}
decodeBeam=${=DECODE_BEAM:-"300.0 250.0 250.0"}; decodeBeam=( $=decodeBeam )
decodeTransDir=${DECODE_TRANS_DIR:-""}
decodeTransExt=${DECODE_TRANS_EXT:-mllr}
decodePattern=${DECODE_PATTERN:=$adaptPattern}
decodeBlockSize=${DECODE_BLOCK_SIZE:=$decodeBlockSize}
decodeCD=${DECODE_CD:-0}
decodeLatices=${DECODE_LATICES:-""}

# Score
scoreReference=${SCORE_REFERENCE:-$wordMLF}
decodeWordList=${DECODE_WORDS:-wordlist.txt}

# InitMLP
seed=${SEED:-random.bin}
createTriphonePfileSpk=${CREATE_TRIPHONE_BIN_SPK:-$binDir/mlf2pfile_triphone_spk.pl}
feacat=${FEACAT:-$(which feacat)}
labcat=${LABCAT:-$(which labcat)}
trainLabels=${TRAIN_LABELS:-hmm-list.txt}

targetTRN=targetTRN.pfile
targetDEV=targetDEV.pfile
targetTST=targetTST.pfile
featTRN=${FEAT_TRN:-$featName-TRN.pfile}
featDEV=${FEAT_DEV:-$featName-DEV.pfile}
featTST=${FEAT_TST:-$featName-TST.pfile}
if [ ! -z ${FEAT_NAME2} ]
then
    featTRN2=${FEAT_NAME2}-TRN.pfile
    featDEV2=${FEAT_NAME2}-DEV.pfile
    featTST2=${FEAT_NAME2}-TST.pfile
fi

#input
trnList=${TRN_LIST:-trn.list}
devList=${DEV_LIST:-dev.list}
trnMLF=${TRN_MLF:-trn.mlf}
devMLF=${DEV_MLF:-dev.mlf}
tstMLF=${TST_MLF:-tst.mlf}

#train MLP
pfile_concat=${PFILE_CONCAT:-$(which pfile_concat)}
pfile_info=${PFILE_INFO:-$(which pfile_info)}
pfile_print=${PFILE_PRINT:-$(which pfile_print)}
pfile_create=${PFILE_CREATE:-$(which pfile_create)}
pfile_klt=${PFILE_KLT:-$(which pfile_klt)}
pfile_ftrcombo=${PFILE_FTRCOMBO:-$(which pfile_ftrcombo)}

normMode=${NORM_MODE:-utts}
normMode2=${NORM_MODE2:-utts}
normFile=${NORM_FILE:-''}
normFile2=${NORM_FILE2:-''}
ftr2Offset=${FTR2_OFFSET:-''}
windowExt=${WINDOW_EXTENT:-9}
windowExt2=${WINDOW_EXTENT2:-0}
trnCacheFrame=${TRN_CACHE_FRAME:-500000}
nParams=${NPARAMS:--1}
outputDim=${OUTPUT_DIM:--1}
bunchSize=${BUNCHSIZE:-1024}
threads=${THREADS:-1}
learnRateSchedule="newbob"
learnRateVals=${LEARN_RATE:-0.0008}
learnRateScale=0.5
deltaOrder=${DELTA_ORDER:-2}
deltaOrder2=${DELTA_ORDER2:-0}
#same delta calculation than HTK
deltaWin=${DELTA_WIN:-5}
deltaWin2=${DELTA_WIN2:-5}
qnstrn=${QNSTRN:-$(which qnstrn)}
qnsfwd=${QNSFWD:-$(which qnsfwd)}
qncopy=${QNCOPY:-$(which qncopy)}
qnmultitrn=${QNMULTITRN:-$(which qnmultitrn)}
qnmultifwd=${QNMULTIFWD:-$(which qnmultifwd)}
nParamsPart=${PARAM_PART:-10}
initWeightFile=${INIT_WEIGHT_FILE:-}
mlp3_hidden_size=${HIDDEN_UNITS:-}
mlpHiddenSize=${HIDDEN_UNITS:-}
mlpWeightFormat=${MLP_WEIGHT_FORMAT:-matlab}
mlpBnSize=${MLP_BN_SIZE:-13}
mlpNLayers=${MLP_NLAYERS:-3}
mlpLRMultiplier=${MLP_LR_MULTIPLIER:-1.0}
mlpWeightFile=${MLP_WEIGHT_FILE:-weights.mat}
initRandomBiasMin=${INIT_RANDOM_BIAS_MIN:-}
initRandomBiasMax=${INIT_RANDOM_BIAS_MAX:-}
initRandomWeightMin=${INIT_RANDOM_WEIGHT_MIN:-}
initRandomWeightMax=${INIT_RANDOM_WEIGHT_MAX:-}


priorFile=${PRIOR_FILE:-priors.txt}
divisionInput=${DIVISION_INPUT:-$activationFile}
divisionOutput=${DIVISION_OUTPUT:-division-out.txt}
divisionDim=${DIVISION_DIM:-1}

#forward MLP
activationID=${ACTIVATION_ID:-out}
featForward=${FORWARD_FILE:-$featName-TST.pfile}
outputType=${MLP_OUTPUT_TYPE:-softmax}
mlpOutHtkDir=${MLP_OUT_HTK_DIR:-}

# tandem features
mlpFeatWarping=${MLP_FEAT_WARPING:-0}
mlpTandemTrain=${MLP_TANDEM_TRAIN:-0}
mlpTandemTrainSent=${MLP_TANDEM_TRAIN_SENT:-0}
mlpTandemTest=${MLP_TANDEM_TEST:-0}
mlpTandemStats=${MLP_TANDEM_STATS:-mlp-tandem-stats}
pcaThreshold=${PCA_THRESHOLD:-0.99}
pcaFeatDimension=${PCA_FEAT_DIM:-$featDimension}

#input
tstList=${TST_LIST:-tst.list}
hiddenDim=${HIDDEN_DIM:-1}
featpad=${FEAT_PAD:-4}
featOffset=${FEAT_OFFSET:-0}
featOffset2=${FEAT_OFFSET2:-0}
activationFormat=${ACTIVATION_FORMAT:-pfile}

#SAT
retrainInSuffix=${RETRAIN_IN_SUFFIX:-}
retrainOutSuffix=${RETRAIN_OUT_SUFFIX:-}

#MLP_decode
hvite_kl=${HVITE_KL:-$(which HVite_kl)}
hvite_rkl=${HVITE_RKL:-$(which HVite_rkl)}
hvite_skl=${HVITE_SKL:-$(which HVite_skl)}
initHMM=$binDir/init_HMM.py
createInitialModels=${CREATE_INITIAL_MODELS:-$binDir/create_initial_models.py}
createHTKHMMS=$binDir/get_htk_hmm.py
activationFile=${ACTIVATION_FILE:-activation.txt}
phonelist=${PHONE_LIST_FILE:-outphones}
model_name=${MODEL_NAME:-base.macro}
modelCreationType=${MODEL_TYPE:-delta}


#klmap
initklhmm=$binDir/initKLHMM-oneFile.py
inphonetype=${INPHONES:-$phoneSet}
outphonetype=${OUTPHONES:-$phoneSet}
outdict=${OUTDICT:-${dictDir}/${dictName}}
mlf2files=$binDir/mlf2asciifiles.sh
mlf2files_perl=$binDir/mlf2asciifiles.pl
klhmmtrn=${KL_HMM_TRN:-viterbi_training}
klMultiList=${KL_HMM_MULTI_LIST:-}
klMultiInitList=${KL_HMM_MULTI_INIT_LIST:-$klMultiList}
klhmmalign=${KL_HMM_ALIGN:-get_state_labels_hybrid}
kldistance=${KL_DISTANCE:-rkl}
klStates=${KL_STATES:-3}
kltrniter=20
klViterbiIter=${KL_VITERBI_ITER:-1}
klAdaptData=${ADAPT_DATA:-$featsDir/${featName}-adapt.pfile}
klmap=${KL_MAP:-KLMap}
kldecision=${KL_DECISION:-0}
klalpha=${KL_ALPHA:--1}
klAdaptationMode=${KL_ADAPTATION_MODE:--1}
inPostFile=${INPOSTFILE:-inpost.txt}
outPostFile=${OUTPOSTFILE:-outpost.txt}
weightsfile=${KL_WEIGHTS_FILE:-weights.txt}
mlfexpand=$binDir/expandmlf.pl
expandModels=$binDir/expandKLModels.pl
klCdep=${KL_CDEP:-0}
priordivision=${KL_MAP_NORMALIZE:-1}
klSeedDir=${KL_SEED_DIR:-}

#KL-HMM training
ID=${ID:-mono}
seedID=${SEED_ID:-}
contextOrder=${CONTEXT_ORDER:-0}
createKLStats=$binDir/createKLstats.pl
mmfParser=${MMF_PARSER:-mmf-parser}

klhhed=${KL_HHED:-HHEd_kl}
klCreateStats=${KL_CREATE_STATS:-1}
mdlfactor=0.1
crossWord=${CROSS_WORD:-1}

tmModelDir=${TM_MODEL_DIR:-hmm-trimap}
tmMLF=${TM_MLF:-align-trimap.mlf}
triMinCount=${TRI_MIN_COUNT:-119}
tmDist=${TRI_MAP_DISTANCE:-htk}
ClearHTKmono=${CLEAR_HTK_MONO:-mmf-parser-trimap}
UntieModels=${UNTIE_MODELS:-untieModels}
counts=${TRIMAP_COUNTS:-counts}
mk_triph_map=${ML_TRIPH_MAP:-mk_triph_map}
trimap1=${TRIMAP1:-trimap1}
x_eval2=${X_EVAL2:-x_eval2}
tmskl=${TRI_MAP_SKL_DIST:-skl}
trainTMklHMM=${TRAIN_TM_KLHMM:-true}
useMonoMMF=${USE_MONO_GMM_TM:-false}

binTieMLF=${BIN_TIE_MLF:-$binDir/tieMLF.rb}
tiedMLF=${TIED_MFL:-$alignMLF.tied}
diphModelDir=${DI_MODEL_DIR:-hmm-dimap}
dtmModelDir=${DI_TRI_MODEL_DIR:-hmm-di3map}

# HTS
# Speech analysis parameters
minF0=${MINF0:-66}                # F0 search range
maxF0=${MAXF0:-1000}
sampFreq=${SAMPFREQ:-16000}       # Sampling frequency (16kHz)
frameShift=${FRAMESHIFT:-5}       # Frame shift in point (0.005s)
mgcOrder=${MGCORDER:-24}          # order of MCEP analysis
bndapOrder=${BNDAPORDER:-21}      # order of band aperiodicity

# Speech synthesis parameters
alpha=${ALPHA:-0.42}
fftLen=${FFTLEN:-1024}
genType=${GENTYPE:-0}
synthesisTrainingDir=${SYNTHESIS_TRAINING_DIR:-../train}
synthesisLabelDir=${SYNTHESIS_LABEL_DIR:-../test-labels}
synthesizer=${SYNTHESIZER:-HMGenS}
hts_engine_straight=${HTS_ENGINE_STRAIGHT:-$(which hts_engine_straight)}

# Training
nPhonemes=${NPHONEMES:-41}
sentenceDelimiter=${SENTENCE_DELIMITER:-/J}
reContextClustering=${RECLUSTERING:-5}
ttsContext=${TTS_CONTEXT:-full}

