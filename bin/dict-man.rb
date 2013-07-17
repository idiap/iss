#!/usr/bin/ruby
#
# Copyright 2011 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, February 2011
#

def usage()
  puts "Usage: dict-man.rb [options] dictionary1 dictionary2 ...
  -h   Prints this help
  -v n Set verbosity to n
  -o f Write dictionary to file f
  -a   Append mode: Extend an existing file rather than overwrite
  -p f Write phone list to file f
  -c   Include phone counts in phone list
  -s p Append phone p to the end of each pronunciation
  -w f Restrict to word list f
  -b   Delete output symbols (in square brackets before pronunciation)
  -uc  Convert to upper case
  -lc  Convert to upper case
  -u f Report unknown (out of vocabulary) words to file f
  -1   Restrict words to a single pronunciation
"
end

# Loop over the command line.  Dictionaries are the unqualified
# arguments
writeMode = "w"
sourceDict = []
appendPhone = []
while arg = ARGV.shift
  case arg
  when "-h"
    usage
    exit 0
  when "-v"
    verbose = ARGV.shift.to_i
  when "-o"
    targetDict = ARGV.shift
  when "-a"
    writeMode = "a"
  when "-p"
    phoneSet = ARGV.shift
  when "-c"
    phoneCounts = 1
  when "-s"
    appendPhone.push ARGV.shift
  when "-w"
    wordList = ARGV.shift
  when "-b"
    deleteOutput = true
  when "-uc"
    upper = true
  when "-lc"
    lower = true
  when "-u"
    oovList = ARGV.shift
  when "-1"
    onePron = true
  else
    # Dictionary
    sourceDict.push arg
  end
end

# Normally it should shut up and get on with it
if verbose
  puts "This is dict-man"
end

# Load word list into a hash
words = {}
if wordList
  File.open(wordList, "r") do |file|
    file.each_line do |line|
      line.gsub!(/\\/, '')   # Remove escapes
      words[line.chomp] = 0
    end
  end
end

# Loop over input dictionaries.  The main dictionary is a hash
# (dictionary) of arrays (pronunciations)
dict = {}
sourceDict.each do |d|
  File.open(d, "r") do |file|
    file.each_line do |line|
      #next if line =~ /^\#/
      line.gsub!(/\\/, '')   # Remove escapes
      word, pron = line.chomp.split(' ', 2)
      word.upcase!   if upper
      word.downcase! if lower
      next if wordList && !words[word]
      pron.sub!(/\[.*\]/, '') if deleteOutput
      if dict[word] == nil
        dict[word] = []
        dict[word].push pron
      elsif !onePron
        dict[word].push pron
      end
    end
  end
  if verbose
    printf "%s: %d pronunciations\n", d, dict.length
  end
end

# Write phone set
if phoneSet
  phone = {}

  # Count all phones in the dictionary
  dict.keys.each do |word|
    dict[word].each do |pron|
      pron.split(' ').each do |ph|
        if !phone[ph]
          phone[ph] = 0
        end
        phone[ph] += 1
      end
    end
  end

  # Print them
  File.open(phoneSet, "w") do |file|
    phone.keys.sort.each do |ph|
      if phoneCounts
        file.printf "%s %d\n", ph, phone[ph]
      else
        file.printf "%s\n", ph
      end
    end
  end

end

# Write output file
if targetDict
  File.open(targetDict, writeMode) do |file|
    dict.keys.sort.each do |word|
      w = word.gsub(/([\"\'])/, '\\\\\\1')  # Yes, six.  Why?
      dict[word].each do |pron|
        if appendPhone.length > 0
          # Append the phones in the list
          appendPhone.each do |ph|
            file.printf "%s\t%s %s\n", w, pron, ph
          end
        else
          # Raw dictionary
          file.printf "%s\t%s\n", w, pron
        end
      end
    end
  end
end

if oovList
  if !words
    printf "Must specify a word list for unknown word discovery\n"
    exit 1
  end
  File.open(oovList, "w") do |file|
    words.keys.sort.each do |w|
      if !dict[w]
        file.printf "%s\n", w
      end
    end
  end
end
