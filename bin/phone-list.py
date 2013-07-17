#!/usr/bin/env python3
#
# Copyright 2010 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   David Imseng, November 2010

#
# Extract Phonelist from csv datafile
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
#level='info'

#create logger
LEVELS = {'debug': logging.DEBUG,
          'info': logging.INFO,
          'warning': logging.WARNING,
          'error': logging.ERROR,
          'critical': logging.CRITICAL}

logger=logging.getLogger("log message")


#create option parser

parser = OptionParser(option_class=MyOption)
parser.add_option("-i", "--ID", dest="phoneID", help="Phoneme ID", metavar="PHONEID", type="string")
parser.add_option("-d", "--data", dest="datafile", help="Datafile containing conversion information (.csv)", metavar="DATFILE", type="string")
parser.add_option("-l", "--loglevel", dest="clevel", help="Log level", metavar="LOGLEVEL", type="string", default='info')
parser.add_option("-m", "--mapping", dest="map", help='Use the specified mapping (to convert some phoneme symbols). Different mappings should be separated by ";" and the values with "," (i.e. 2,_2_;9,_9_).'.format(map), metavar="PHONESET", type="dict")


(options, args) = parser.parse_args()

if(options.datafile): 
	logger.info('CSV filename set to {}.'.format(options.datafile))
	filename=options.datafile
else:
	parser.error("The data file needs to be specified.")

if(options.phoneID): 
	logger.info('Phone ID set to {}.'.format(options.phoneID))
	phoneID=options.phoneID
else:
	parser.error("The Phone ID needs to be specified.")

if(options.map):
	map=options.map
	logger.info('Mapping is set: {}.'.format(map))
else:
	map=dict()
	logger.info('No mapping specified')



clevel=options.clevel;

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



#read the csv file
freader = csv.DictReader(open(filename,'r'))

#get the counts (second column, the first has the fieldnames...)
try:
	if not phoneID in freader.fieldnames:
		sys.exit('PhoneID "%s" not found.' %(phoneID))
	row=next(freader)
	nphones=int(row[phoneID])
	logger.info('Expecting {} phonemes.'.format(str(nphones)))
except csv.Error as e:
	sys.exit('file %s, line %d: %s' % (filename, freader.line_num, e))


#list to get all the data
#read the file and check if all the SAMPA symbols are there
try:
	for row in freader:
		if ( len(row[phoneID]) != 0 ):
			symbol=row[phoneID]
			if (len(map) > 0):
				for to_map in map.keys():
					if (to_map == symbol):
						symbol={map[symbol]}.pop()

			print('{}'.format(symbol))
			nphones=nphones-1
except csv.Error as e:
	sys.exit('file %s, line %d: %s' % (filename, freader.line_num, e))

if( nphones != 0 ):
	sys.exit('Not all phonemes read. (%s missing)' % (nphones))

