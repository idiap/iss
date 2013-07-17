#!/usr/bin/env python3
#
# Copyright 2010 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#

#
# Parse Phoneset file in csv format and create question sets
# David Imseng, July 2010
#
import csv, sys, logging 
from optparse import OptionParser

from copy import copy
from optparse import Option, OptionValueError

def check_dict(option, opt, value):
	try:
		tempmap=dict()
		all_maps=parts=value.split(';')
		for x in all_maps:
			this_mapping=x.split(',')
			tempmap[this_mapping[0]]=this_mapping[1]
		return tempmap
	except ValueError:
		raise OptionValueError("option %s: invalid input %r" % (opt, value))

class MyOption (Option):
    	TYPES = Option.TYPES + ("dict",)
    	TYPE_CHECKER = copy(Option.TYPE_CHECKER)
    	TYPE_CHECKER["dict"] = check_dict


#variables to set
#TREETH='$thre'

TREETH='0'
CLUSTERTH=500.0
STATFILE='$stats'
ALLTRILIST='$alltrph'
TIEDOUT='$outd/tri.tied'
TREEOUT='$outd/tdcTree'
#sil={'sil'}
sil=None
clevel='info'
states={2,3,4}
sp_match=3


#FRENCH
#ps='SD_SF'
#map={'2':'_2_','9':'_9_','9~':'_9_~','&/':'_2___9_','E/':'e_E','O/':'o_O'} 

#ENGLISH
#ps='SD_EN'
#map={'3:':'_3_:'} 

#GERMAN
#map={'2:6':'_2_:6','96':'_9_6', '9':'_9_', '2:':'_2_:','?':'_?_'}




#create logger
LEVELS = {'debug': logging.DEBUG,
          'info': logging.INFO,
          'warning': logging.WARNING,
          'error': logging.ERROR,
          'critical': logging.CRITICAL}

logger=logging.getLogger("log message")
logger.setLevel(LEVELS.get(clevel, logging.NOTSET))
# create console handler and set level to debug
ch = logging.StreamHandler()
ch.setLevel(LEVELS.get(clevel, logging.NOTSET))
# create formatter
formatter = logging.Formatter("%(name)s - %(asctime)s - %(levelname)s - %(message)s")
# add formatter to ch
ch.setFormatter(formatter)
# add ch to logger
logger.addHandler(ch)

#list of valid phonesets
phonesets ={'SD_EN','SD_ES','SD_IT','SD_SF','SD_SZ','SD_IT_wo@','CMUbet'}

#create option parser
parser = OptionParser(option_class=MyOption)
parser.add_option("-f", "--file", dest="cluster_filename", help="questions to FILE [stdout will be used if not specified]", metavar="FILE", type="string")
parser.add_option("-c", "--config", dest="config_filename", help="write mktri.hed to FILE [nothing written if not specified]", metavar="FILE", type="string")
parser.add_option("-i", "--infile", dest="in_filename", help="read from FILE", metavar="FILE", type="string")
parser.add_option("-p", "--phoneset", dest="ps", help='Use the specified phoneset. (One out of {})'.format(phonesets), metavar="PHONESET", type="string")
parser.add_option("-s", "--silmodel", dest="sil", help='Set the silence model identity', metavar="PHONESET", type="string")
parser.add_option("-m", "--mapping", dest="map", help='Use the specified mapping (to convert some phoneme symbols). Different mappings should be separated by ";" and the values with "," (i.e. 2,_2_;9,_9_).'.format(map), metavar="PHONESET", type="dict")
parser.add_option("-b", "--first_colum", dest="scolumn", help='The first column that contains questions.', metavar="SCOLUMN", type="int")
parser.add_option("-t", "--treeth", dest="treeth", help='The maximum increase of likelihood allowed for any question at any node during clustering', metavar="TREETH", type="float")

(options, args) = parser.parse_args()

if (options.treeth):
	TREETH=options.treeth

if(options.cluster_filename): 
	logger.info('cluster.template filename set to {}.'.format(options.cluster_filename))
	qsOutName=options.cluster_filename
	qsOut=open(qsOutName,'w')
else:
	qsOut=None
	qsOutName="stdout"
	logger.info('No filename set for the cluster.template file. Printing to stdout...')

if(options.config_filename): 
	logger.info('mktri.hed filename set to {}.'.format(options.config_filename))
	tiConfigName=options.config_filename
	tiConfig=open(tiConfigName,'w')
else:
	tiConfigName="stdout"
	tiConfig=None
	logger.info('No filename set for the mktri.hed file. Printing to stdout...')

if(options.in_filename):
	filename=options.in_filename
else:
	parser.error("The input file needs to be specified.")

if(options.ps):
	ps=options.ps
else:
	parser.error("The phoneset needs to be specified.")

if(options.sil):
	sil={options.sil}

if(options.map):
	map=options.map
	logger.info('Mapping is set: {}.'.format(map))
else:
	map=dict()
	logger.info('No mapping specified')


#read the csv file
freader = csv.DictReader(open(filename,'r'))
if not ps in freader.fieldnames:
	sys.exit('PhoneID "%s" not found.' %(ps))
if(options.scolumn):
	scolumn=options.scolumn
else:
	scolumn=freader.fieldnames.index("question count")+1

print('Start column {}'.format(scolumn))

#get the counts (second column, the first has the fieldnames...)
try:
	row=next(freader)
	IPAcount=row['IPA']
	SAMPAcount=row['SAMPA']
	logger.info('Expecting {} IPA entries and {} SAMPA entries.'.format(str(IPAcount), str(SAMPAcount)))
except csv.Error as e:
	sys.exit('file %s, line %d: %s' % (filename, freader.line_num, e))



#list to get all the data
data=[]
#read the file and check if all the SAMPA symbols are there
try:
	for row in freader:
		if ( (len(row['SAMPA']) == 0) and (data.len < SAMPAcount) ):
			sys.exit('Empty SAMPA symbol in file %s, at line %d' % (filename, freader.line_num))
		data.append(row)
except csv.Error as e:
	sys.exit('file %s, line %d: %s' % (filename, freader.line_num, e))
logger.info('Read {} data-rows from the csv file ({}).'.format(str(len(data)), filename))



logger.info('Writing the question set file... ({}).'.format(str(qsOutName)))
#Go trough all the questions (start in "scolumn")
#print('#! /bin/bash', file=qsOut)
#print('cat <<EOF', file=qsOut)
#print('RO {} "{}"'.format(str(CLUSTERTH),str(STATFILE)), file=qsOut)
#print('TR 0', file=qsOut)


for question in freader.fieldnames[scolumn:]:
	#store the phonemes that use that question
	sel_phonemes=[]
	#Find the phonemes that answer a question positively
	for x in data:
		symbol = {x[ps] for y in x[question] if y in '1'}-{''}
		if (len(symbol) > 0 ):
			if (len(map) > 0):
				to_compare=symbol.pop()
				for to_map in map.keys():
					if (str(to_map) == str(to_compare)):
						symbol = {map[to_compare]}
						symbol = symbol.pop()
						break
					else:
						symbol = to_compare
			sel_phonemes.append(symbol)
	if (len(sel_phonemes) > 0 ):
		r_sel_phonemes = {'"*+'+str(x)+'"' for x in sel_phonemes}
		l_sel_phonemes = {'"'+str(x)+'-*"' for x in sel_phonemes}
		c_sel_phonemes = {'"*-'+str(x)+'+*"' for x in sel_phonemes}

		print('QS "{}_{}"\t{{ {} }}'.format('R',question,','.join(r_sel_phonemes)), file=qsOut)
		print('QS "{}_{}"\t{{ {} }}'.format('L',question,','.join(l_sel_phonemes)), file=qsOut)
		print('QS "{}_{}"\t{{ {} }}'.format('C',question,','.join(c_sel_phonemes)), file=qsOut)


for x in data:
	phoneme = x[ps]
	if (len(phoneme) > 0):
		for to_map in map.keys():
			if (to_map == phoneme):
				phoneme = {map[phoneme]}
		print('QS "{}_{}"\t{{ {} }}'.format('R',''.join(phoneme), '"*+'+''.join(phoneme)+'"'), file=qsOut)
		print('QS "{}_{}"\t{{ {} }}'.format('L',''.join(phoneme), '"'+''.join(phoneme)+'-*"'),file=qsOut)
		print('QS "{}_{}"\t{{ {} }}'.format('C',''.join(phoneme), '"*-'+''.join(phoneme)+'+*"'),file=qsOut)

if sil:
	for x in sil:
		print('QS "{}_{}"\t{{ {} }}'.format('R',x, '"*+'+x+'"'), file=qsOut)
		print('QS "{}_{}"\t{{ {} }}'.format('L',x, '"'+x+'-*"'), file=qsOut)

logger.info('Questions written to file "{}".'.format(str(qsOutName)))

print('TR 2', file=qsOut)
for x in data:
	phoneme = x[ps]
	if (len(phoneme) > 0):
		for to_map in map.keys():
			if (to_map == phoneme):
				phoneme = {map[phoneme]}

		for state in states:
			phonID=''.join(phoneme)
			phoVar={'"'+phonID+'"','"*-'+phonID+'+*"','"*-'+phonID+'"','"'+phonID+'+*"'}
			print('TB {} "ST_{}_{}"\t{{({}).state[{}]}}'.format(str(TREETH),''.join(phoneme), state, ','.join(phoVar),state), file=qsOut)
		if tiConfig:
			print('TI T_{} {{({}).transP}}'.format(''.join(phoneme), ','.join(phoVar)), file=tiConfig)

## PNG - we don't need to tie sil as it's monophone
## if sil:
## 	for x in sil:
## 		for state in states:
## 			if (state == sp_match):
## 				silVar={'"'+x+'"','"*-'+x+'"','"'+x+'+*"', '"sp"'}
## 			else:
## 				silVar={'"'+x+'"','"*-'+x+'"','"'+x+'+*"'}
## 				print('TB {} "ST_{}_{}"\t{{({}).state[{}]}}'.format(str(TREETH),x, state, ','.join(silVar),state), file=qsOut)
## 				if tiConfig:
## 					print('TI T_{} {{({}).transP}}'.format(x,','.join(silVar)), file=tiConfig)
logger.info('TB entries written to file "{}".'.format(str(qsOutName)))


#print('TR 1', file=qsOut)
#print('AU "{}"'.format(str(ALLTRILIST)), file=qsOut)
#print('CO "{}"'.format(str(TIEDOUT)), file=qsOut)
#print('ST "{}"'.format(str(TREEOUT)), file=qsOut)
#print('EOF', file=qsOut)
logger.info('... file "{}" written.'.format(str(qsOutName)))
