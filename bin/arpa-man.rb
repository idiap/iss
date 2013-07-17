#!/usr/bin/ruby
#
# Copyright 2011 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, August 2011
#
def usage()
  puts "Usage: arpa-man.rb [options] language-model
  -h   Prints this help
  -v n Set verbosity to n
  -o f Write to file f
  -u w Set unknown word to w [<UNK>]
  -z   Delete n-grams containing unknown word
"
end

# Loop over the command line.  LMs are the unqualified arguments
sourceLM = []
unknown = "<UNK>"
while arg = ARGV.shift
  case arg
  when "-h"
    usage
    exit 0
  when "-v"
    verbose = ARGV.shift.to_i
  when "-o"
    outFile = ARGV.shift
  when "-u"
    unknown = ARGV.shift
  when "-z"
    zapUnk = true
  else
    # LM
    sourceLM.push arg
  end
end

if sourceLM.size > 1
  puts "Sorry, only one LM right now"
  exit 1
end

print "Loading ", sourceLM[0], "\n"
arpa = []
ngram = []
File.open(sourceLM[0], "r") do |file|
  want = "data"
  grams = -1
  file.each_line do |line|
    line.chomp!
    next if line == ""
    case want
    when "data"
      if line == "\\data\\"
        want = "ngram"
      end
    when "ngram"
      if line.sub!(/^ngram /, "")
        n, c = line.split('=')
        n = n.to_i - 1
        ngram[n] = c.to_i
        arpa[n] = {}
        printf " expect %d %d-grams\n", c, n+1
      elsif line.match(/^\\(\d+)-grams:/)
        grams = $1.to_i - 1
        want = "grams"
      end
    when "grams"
      if line.match(/^\\(\d+)-grams:/o)
        grams = $1.to_i - 1
        next
      end
      if line == "\\end\\"
        want = "none"
        break
      end
      field = line.split
      gram = field[1..(grams+1)]
      next if (zapUnk and gram.include?(unknown))
      arpa[grams][gram] = []
      arpa[grams][gram].push(field[0])
      bo = field[grams+2]
      arpa[grams][gram].push(bo) if bo
    end
  end
  if (want != "none")
    printf "file ended in state %s\n", want
  end
end

# Report what was actually found
(0..arpa.size-1).each do |n|
  printf " retain %d %d-grams\n", arpa[n].size, n+1
end

if outFile
  print "Writing ", outFile, "\n"
  File.open(outFile, "w") do |file|
    file.puts "Written by arpaman.rb"

    # N-gram counts
    file.puts "\n\\data\\"
    (0..arpa.size-1).each do |n|
      file.printf "ngram %d=%d\n", n+1, arpa[n].size
    end

    # N-grams
    (0..arpa.size-1).each do |n|
      file.printf "\n\\%d-grams:\n", n+1
      arpa[n].keys.sort.each do |gram|
        g = gram.join " "
        a = arpa[n][gram]
        file.printf "%s\t%s", a[0], g
        if (a[1])
          file.printf "\t%s", a[1]
        end
        file.printf "\n"
      end
    end

    # End
    file.puts "\n\\end\\"
  end
end
