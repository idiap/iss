#!/usr/bin/ruby
#
# Copyright 2011 by Idiap Research Institute, http://www.idiap.ch
#
# See the file COPYING for the licence associated with this software.
#
# Author(s):
#   Phil Garner, January 2011
#

require "csv"

class PhoneSet

  # The initialiser just reads the CSV file
  def initialize(csvFile)
    @table = CSV.read(csvFile)
    @label = @table.shift  # The first row is the labels
    @count = @table.shift  # The second row is just a bunch of counts
  end

  # Get a phone list given the name.
  # The phones are in the same column as the label; some may be blank.
  def phoneList(name)
    i = @label.index(name)
    list = []
    @table.each do |r|
      if r[i]
        list.push r[i]
      end
    end
    return list
  end

end

ps = PhoneSet.new("../lib/phoneset/PhoneSets.csv")
pl = ps.phoneList("SAMPA")

puts pl
