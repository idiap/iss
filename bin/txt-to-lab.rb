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

txtFile = []
ext = "lab"
while arg = ARGV.shift
  case arg
  when "-w"
    wordFile = ARGV.shift
  when "-c"
    wordCounts = true
  when "-e"
    ext = ARGV.shift
  else
    txtFile.push arg
  end
end

word = {}
print "#!MLF!#\n"
txtFile.each do |name|
  File.open(name, "r") do |file|
    file.each_line do |line|
      # Print the lab (MLF) format
      printf "\"*/%s.%s\"\n", File.basename(name, ".txt"), ext

      line.chomp!
      line.split(' ').each do |w|
        if ((w != ".") && (w != ""));
          # Print the word
          print w, "\n"

          # Maintain a word list
          if !word[w]
            word[w] = 0
          end
          word[w] += 1
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
