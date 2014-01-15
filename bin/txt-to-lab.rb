#!/usr/bin/ruby
#
# Copyright 2013 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, October 2013
#

#
# Convert txt file to label file
# This is really just dot-to-lab with all the dot stuff removed.
#

def usage()
  puts "Usage: txt-to-lab.rb [options] file1.txt file2.txt ...
  -h       Prints this help
  -w FILE  Output word to file FILE
  -c       Include word counts in word file
  -e xyz   Set label file extension to xyz [lab]
  -b       Blacklist the given pattern (omit instances from file list)
  -l FILE  Output file list to FILE
"
end


txtFile = []
ext = "lab"
blackList = []
files = []
while arg = ARGV.shift
  case arg
  when "-h"
    usage
    exit 0
  when "-w"
    wordFile = ARGV.shift
  when "-c"
    wordCounts = true
  when "-e"
    ext = ARGV.shift
  when "-l"
    fileFile = ARGV.shift
  when "-b"
    blackList.push ARGV.shift
  else
    txtFile.push arg
  end
end

word = {}
print "#!MLF!#\n"
txtFile.each do |name|
  File.open(name, "r") do |file|
    file.each_line do |line|
      line.chomp!

      # Check for blacklisting
      black = false
      blackList.each do |bl|
        if line.match(bl)
          black = true
          break
        end
      end

      # Miss out the whole utterance if blacklisted word occurs
      next if black;

      # Print the lab (MLF) format
      base = File.basename(name, ".txt")
      printf "\"*/%s.%s\"\n", base, ext

      if fileFile
        files.push name
      end

      line.split(' ').each do |w|
        if ((w != ".") && (w != ""))
          # Split acronyms
          wa = [w]
          if (/[A-Z][A-Z]+/.match(w))
            wa = w.split('')
          end

          # Another loop in case the word was split
          wa.each do |sw|
            # Print the word
            print sw, "\n"

            # Maintain a word list
            if !black
              if !word[sw]
                word[sw] = 0
              end
              word[sw] += 1
            end
          end
        end
      end
      print ".\n";
    end
  end
end

if wordFile
  File.open(wordFile, "w") do |file|
    word.keys.sort.each do |w|
      if wordCounts
        file.printf "%s %d\n", w, word[w]
      else
        file.printf "%s\n", w
      end
    end
  end
end

if fileFile
  File.open(fileFile, "w") do |file|
    files.each do |f|
      file.puts f
    end
  end
end
