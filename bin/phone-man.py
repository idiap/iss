#!/usr/bin/env python3
#
# Copyright 2010 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   David Imseng, July 2010
#   Phil Garner, March 2013
#   Bastian Schnell, July 2017

#
# Parse Phone-Set file in csv format and create question sets
#
import csv
import sys
import os
import re
from copy import copy
from optparse import OptionParser, Option, OptionValueError


def check_dict(option, opt, value):
    try:
        tempmap = dict()
        all_maps = parts = value.split(';')
        for x in all_maps:
            this_mapping = x.split(',')
            tempmap[this_mapping[0]] = this_mapping[1]
        return tempmap
    except ValueError:
        raise OptionValueError("option %s: invalid input %r" % (opt, value))


class MyOption (Option):
    TYPES = Option.TYPES + ("dict",)
    TYPE_CHECKER = copy(Option.TYPE_CHECKER)
    TYPE_CHECKER["dict"] = check_dict


# Find the installation root
issRoot = os.environ.get("ISSROOT")
if issRoot == None:
    # Assume we are run as $ISSROOT/bin/phone-man.py
    issRoot = os.path.abspath(sys.argv[0])
    for i in range(2):
        issRoot = os.path.split(issRoot)[0]
    print("ISSROOT guessed to be", issRoot)

# Create option parser
parser = OptionParser(option_class=MyOption)
parser.add_option(
    "-f", "--file", dest="qsOutName", metavar="FILE", type="string",
    help="questions to FILE [stdout will be used if not specified]"
)
# parser.add_option(
#    "-c", "--config", dest="tiConfigName", metavar="FILE", type="string",
#    help="write mktri.hed to FILE [nothing written if not specified]"
#)
parser.add_option(
    "-i", "--infile", dest="csvFile", metavar="FILE", type="string",
    default="{}/lib/phoneset/PhoneSets.csv".format(issRoot),
    help="read from FILE"
)
parser.add_option(
    "-p", "--phoneset", dest="ps", metavar="PHONESET",
    type="string", default="CMUbet",
    help='Use the specified phone-set.'
)
parser.add_option(
    "-s", "--silmodels", dest="sil", metavar="PHONE",
    type="string", default='',
    help='Set the silence model identity, commas separated'
)
parser.add_option(
    "-m", "--mapping", dest="map", metavar="PHONESET", type="dict",
    help='Use the specified mapping (to convert some phoneme symbols).  Different mappings should be separated by ";" and the values with "," (i.e. 2,_2_;9,_9_).'.format(
        map)
)
parser.add_option(
    "-t", "--treeth", dest="treeThres", metavar="treeThres",
    type="float", default="0",
    help='The maximum increase of likelihood allowed for any question at any node during clustering'
)
parser.add_option(
    "-q", "--quin", dest="quin", action="store_true", default=False,
    help='Output questions for quin-phones as well as tri-phones'
)
parser.add_option(
    "-F", "--full", dest="full", action="store_true", default=False,
    help='Output questions for full context (i.e., for TTS).  Note that this does not imply -q, for TTS you probably need both.'
)
parser.add_option(
    "-r", "--reduced", dest="reduced", action="store_true", default=False,
    help='Use reduced set of questions. Remove questions unnecessary for DNN TTS.'
        +'u.g. Use only C_Vowel and not L_Vowel and R_Vowel.'
        +'Also use the reduced set of static questions.'
)

(options, args) = parser.parse_args()

# Set options depending on options
if(options.qsOutName):
    print('Question set file: {}.'.format(options.qsOutName))
    options.qsOutName = options.qsOutName
    options.qsOut = open(options.qsOutName, 'w')
else:
    options.qsOutName = "stdout"
    options.qsOut = None
    print('No filename set for the question file. Printing to stdout.')

# if(options.tiConfigName):
#    print('mktri.hed file: {}.'.format(options.tiConfigName))
#    tiConfigName = options.tiConfigName
#    tiConfig = open(tiConfigName, 'w')
# else:
#    tiConfigName = "stdout"
#    tiConfig = None
#    print('No filename set for the mktri.hed file. Printing to stdout.')

if(options.map):
    map = options.map
    print('Mapping is set: {}.'.format(map))
else:
    map = dict()
    print('No mapping specified')


class PhoneSets:
    """
    Handles phone sets stored in the PhoneSets spreadsheet
    """

    def __init__(self, file, quin=False, full=False, reduced=False):
        self.quin = quin
        self.reduced = reduced

        self.formatTri = {
            'L': '{}-*',
            'C': '*-{}+*',
            'R': '*+{}'
        }

        self.formatTirReduced = {
            'C': '*-{}+*'
        }

        self.formatQuin = {
            'LL': '{}^*',
            'L':  '*^{}-*',
            'C':  '*-{}+*',
            'R':  '*+{}=*',
            'RR': '*={}'
        }

        self.formatQuinReduced = {
            'C':  '*-{}+*',
        }
        
        # Full context requires modifying the RR or R phone contexts
        if full:
            self.formatTri['R'] += "@*"
            self.formatQuin['RR'] += "@*"

        # Read the csv file
        freader = csv.DictReader(open(file, 'r'))
        self.scolumn = freader.fieldnames.index("question count") + 1

        # Get the counts (second column; the first has the fieldnames.)
        try:
            row = next(freader)
            self.IPAcount = row['IPA']
            self.SAMPAcount = row['SAMPA']
            print('Expecting {} IPA entries and {} SAMPA entries.'.format(
                  self.IPAcount, self.SAMPAcount)
                  )
        except csv.Error as e:
            sys.exit('%s, line %d: %s' % (file, freader.line_num, e))

        # Read the file and check if all the SAMPA symbols are there
        # Each row becomes an entry in the list "data"
        self.data = []
        try:
            for row in freader:
                if ((len(row['SAMPA']) == 0) and
                        (len(self.data) < int(self.SAMPAcount))):
                    sys.exit('Empty SAMPA symbol in file %s, at line %d'
                             % (file, freader.line_num))
                self.data.append(row)
        except csv.Error as e:
            sys.exit('file %s, line %d: %s'
                     % (options.csvFile, freader.line_num, e))
        print('Read {} data-rows from {}'.format(
            str(len(self.data)), options.csvFile)
        )

        # Array of phone classes
        self.classes = freader.fieldnames[self.scolumn:]

        # if not options.ps in freader.fieldnames:
        #    sys.exit('phone-set "%s" not found.' %(options.ps))

    def _map(self, phoneme):
        for to_map in map.keys():
            if (to_map == phoneme):
                return map[phoneme]
        return phoneme

    def get_phoneset(self, ps):
        phoneset = set()
        for x in self.data:
            phoneme = x[ps]
            if (len(phoneme) > 0):
                phoneme = self._map(phoneme)
                phoneset.add(phoneme)
        return phoneset

    def get_class_phoneset(self, ps, pclass):
        phoneset = set()
        for phone in self.data:
            if phone[pclass] == '1' and phone[ps] != '':
                phoneme = self._map(phone[ps])
                phoneset.add(phoneme)
        return phoneset

    def _format_phone(self, formatStr, phone):
        """
        The quoting may not be necessary; it seems safer though, and
        certainly easy to do.
        """
        return '"' + formatStr.format(phone) + '"'

    def _format_phones(self, formatStr, phones):
        formats = {self._format_phone(formatStr, p) for p in phones}
        str = ','.join(formats)
        return str

    def _question(self, context, formatStr, pclass, phones):
        pstr = self._format_phones(formatStr, phones)
        str = 'QS "{}_{}"\t{{ {} }}\n'.format(context, pclass, pstr)
        return str

    def _questions(self, formatDict, pclass, phones):
        questions = []
        for context in formatDict.keys():
            questions.append(self._question(
                context, formatDict[context], pclass, phones
            ))
        return questions

    def get_class_questions(self, ps):
        # Go through all the questions (start in "scolumn")
        questions = []
        for question in self.classes:
            # Find the phonemes that answer a question positively
            sel_phonemes = self.get_class_phoneset(ps, question)

            # If there are phones in the question, return the questions
            if (len(sel_phonemes) > 0):
                if self.quin:
                    if self.reduced:
                        questions += self._questions(
                            self.formatQuinReduced, question, sel_phonemes
                        )
                    else:
                        questions += self._questions(
                            self.formatQuin, question, sel_phonemes
                        )
                else:
                    if self.reduced:
                        questions += self._questions(
                            self.formatTriReduced, question, sel_phonemes
                        )
                    else:
                        questions += self._questions(
                            self.formatTri, question, sel_phonemes
                        )
        return questions

    def get_phone_questions(self, ps):
        # Regardless of other questions, there is one for each individual phone
        questions = []
        for phoneme in self.get_phoneset(ps):
            if self.quin:
                questions += self._questions(self.formatQuin,
                                             phoneme, [phoneme])
            else:
                questions += self._questions(self.formatTri,
                                             phoneme, [phoneme])
        return questions

    def get_sil_questions(self, sil):
        """
        Silence questions suitable for ASR; that is, just triphone
        contexts and one for the class.  Assume here that contexts
        don't cross silence, i.e., just use the L & R contexts, not
        *^sil-* and the like.
        """
        questions = []
        if len(sil) > 1:
            questions += self._question('L', self.formatTri['L'], "Sil", sil)
            questions += self._question('R', self.formatTri['R'], "Sil", sil)
        for s in sil:
            questions.append(self._question('L', self.formatTri['L'], s, [s]))
            questions.append(self._question('R', self.formatTri['R'], s, [s]))
        return questions

    def get_full_sil_questions(self, sil):
        """
        Silence questions suitable for TTS; that is, all contexts and
        one for the class.  It'll work for ASR too, just some
        questions will be redundant.
        """
        questions = []
        if len(sil) > 1:
            if self.quin:
                questions += self._questions(self.formatQuin, "Sil", sil)
            else:
                questions += self._questions(self.formatTri, "Sil", sil)
        for s in sil:
            if self.quin:
                questions += self._questions(self.formatQuin, s, [s])
            else:
                questions += self._questions(self.formatTri, s, [s])
        return questions

    def _tie(self, threshold, phoneme, state):
        phoVar = {'"' + phoneme + '"', '"*-' + phoneme + '+*"',
                  '"*-' + phoneme + '"', '"' + phoneme + '+*"'}
        str = 'TB {} "ST_{}_{}"\t{{({}).state[{}]}}\n'.format(
            threshold, phoneme, state, ','.join(phoVar), state
        )
        return str

    def get_tie_commands(self, ps, threshold):
        commands = ['TR 2\n']
        states = {2, 3, 4}
        for phoneme in self.get_phoneset(ps):
            for state in states:
                commands.append(self._tie(threshold, phoneme, state))
        return commands

#        if tiConfig:
#            print('TI T_{} {{({}).transP}}'.format(
#                ''.join(phoneme), ','.join(phoVar)
#            ), file=tiConfig)

    def get_syl_vowel_questions(self, ps):
        formatSyl = {
            'C-Syl': '*|{}/C:*',
        }
        questions = []
        for phoneme in ['x', 'novowel']:
            str = 'Vowel==' + phoneme
            questions += self._question(
                'C-Syl', formatSyl['C-Syl'], str, [phoneme]
            )
        vowelre = re.compile('.*vowel.*', re.IGNORECASE)
        for pclass in self.classes:
            if vowelre.match(pclass):
                phones = self.get_class_phoneset(ps, pclass)
                if (len(phones) > 0):
                    questions += self._questions(formatSyl, pclass, phones)
        for phoneme in self.get_class_phoneset(ps, "Vowel"):
            questions += self._questions(formatSyl, phoneme, [phoneme])
        return questions

    def get_static_questions(self, path):
        f = open(path, 'r')
        lines = f.readlines()
        return lines


#
# The main program
#
print(options.qsOutName)
sil = options.sil.split(',')
ps = PhoneSets(options.csvFile, options.quin, options.full, options.reduced)
with open(options.qsOutName, 'w') as f:
    f.writelines(ps.get_class_questions(options.ps))
    f.writelines(ps.get_phone_questions(options.ps))
    if options.full:
        # Basically for TTS
        f.writelines(ps.get_full_sil_questions(sil))
        f.writelines(ps.get_syl_vowel_questions(options.ps))
        if options.reduced:
            static = "{}/lib/phoneset/questions-static_reduced.txt".format(issRoot)
        else:
            static = "{}/lib/phoneset/questions-static.txt".format(issRoot)
        f.writelines(ps.get_static_questions(static))
    else:
        # Basically for ASR
        f.writelines(ps.get_sil_questions(sil))
        f.writelines(ps.get_tie_commands(options.ps, options.treeThres))
