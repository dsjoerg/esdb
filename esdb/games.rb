# Basically, the idea with these "overloads" is to have multiple models/tables
# for a given association, "polymorphic", depending on the assigned Game
#
# So a Match for Sc2 will give you a Sc2::Match::Summary for #summary
#
# Turns out this is relatively tricky to do though, so for now it's all just
# Sc2, with some of the envisioned naming in place. We're so far away from
# supporting any other games that no real effort should be put into this right
# now, obviously.
#
# But ..let's not forget about it completely :)

require 'esdb/games/sc2'
Dir['esdb/games/**/*.rb'].reverse.each {|file| require File.expand_path(file) }
