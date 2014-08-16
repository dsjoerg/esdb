# Because I appear to be too stupid to get Treetop to properly do what I want
# I've tried Citrus and found it to be somewhat more intuitive (better debug
# output too)
#
# All Citrus grammars are loaded here for now. See each grammar for individual
# documentation.
#
# However - the ApiFields grammar remains for now, as I haven't checked if
# Citrus will allow me to do the fancy "& tree hash" magic. It's not really
# required, but I like the approach.. 
# (see api/identities/:id and lib/patch/hash.rb)

Citrus.load 'lib/grammars/stats_param'
