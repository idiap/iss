#!/usr/bin/ruby
#
# Copyright 2011 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, February 2011
#

#
# Convert dot file to label file
#
# In the test data, [] contain noises, e.g., [tongue_click], and we
# don't want those.  In the training, though, we do want them.  That's
# what the command line argument is for.
#

dotFile = []
ext = "lab"
while arg = ARGV.shift
  case arg
  when "-d"
    deleteNoises = true
  when "-w"
    wordFile = ARGV.shift
  when "-c"
    wordCounts = true
  when "-e"
    ext = ARGV.shift
  else
    dotFile.push arg
  end
end

word = {}
print "#!MLF!#\n"
dotFile.each do |name|
  File.open(name, "r") do |file|
    file.each_line do |line|

      # Pick off the label at the end in parentheses
      line.chomp!
      if !line.sub!(/\((\S+)\)\s*$/, '')
        printf "Failed on line %s\n", line
        continue
      end
      label = $1

      # Print the lab (MLF) format
      printf "\"*/%s.%s\"\n", label.downcase, ext
      line.upcase.split(' ').each do |w|

        # Noises are special
        if deleteNoises
          w.gsub!(/\[([^\[\]\s]*)\]/, '')     #  [xx] -> blank
        else
          # It's open what to do here
          # w.gsub!(/\[([^\[\]\s]*)\]/, '\\1'); #  [xx] -> xx
          w.gsub!(/\[([^\[\]\s]*)\]/, '[NOISE]'); #  [xx] -> [NOISE]
        end

        # Otherwise clean up on a word by word basis
        w.gsub!(/\(([^\(\)\s]*)\)/, '') # (xx) -> blank
        w.gsub!(/^[\!\/\<\>]/, '')      # Crap at the beginning
        w.gsub!(/[\!\/\<\>]$/, '')      # Crap at the end
        w.gsub!(/(\S):/, '\\1')         # Colons in words
        w.gsub!(/-$/, '')               # trailing hyphens
        w.gsub!(/\\$/, '')              # trailing backslashes break HTK
        w.gsub!(/\*/, '')               # Mispronounced word markers
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
