#!/idiap/resource/software/python/3.1/i686/bin/python3
#
# Convert Dictionary
# David Imseng, November 2010
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
parser.add_option("-i", "--lexicon", dest="lexicon", help="Input lexicon", metavar="LEXICON", type="string")
parser.add_option("-l", "--loglevel", dest="clevel", help="Log level", metavar="LOGLEVEL", type="string", default='info')
parser.add_option("-m", "--mapping", dest="map", help='Use the specified mapping (to convert some phoneme symbols). Different mappings should be separated by ";" and the values with "," (i.e. 2,_2_;9,_9_).'.format(map), metavar="MAPPING", type="dict")


(options, args) = parser.parse_args()

if(options.lexicon): 
	logger.info('Lexicon set to {}.'.format(options.lexicon))
	lexicon=options.lexicon
else:
	parser.error("The Lexicon needs to be specified.")

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
freader = csv.DictReader(open(lexicon,'r'), fieldnames=['words', 'trans'], restkey={'phones'}, restval={'sil'},dialect=csv.excel_tab)

#get the counts (second column, the first has the fieldnames...)
print('"</s>"\t[]\tsil')
print('"<s>"\t[]\tsil')

try:
	for row in freader:
		all_phones=row['trans'].split(' ')
		for phone in all_phones:
			for to_map in map.keys():
				if (to_map == phone):
					index=all_phones.index(phone)
					all_phones[index]={map[phone]}.pop()
		print('"{}"\t[{}]\t{}'.format(row['words'],row['words'],' '.join(all_phones)))
except csv.Error as e:
	sys.exit('file %s, line %d: %s' % (filename, freader.line_num, e))

