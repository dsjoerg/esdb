#!/Users/david/local/bin/python

import sys

# http://stackoverflow.com/questions/36932/whats-the-best-way-to-implement-an-enum-in-python
def enum(*sequential, **named):
    enums = dict(zip(sequential, range(len(sequential))), **named)
    return type('Enum', (), enums)

Column = enum('match_id', 'gateway', 'winner',
              'average_league', 'summary_league',
              'race1', 'race2', 'seconds',
              'army1', 'army2', 'income1', 'income2',
              'duration_seconds')

now = 0
current_match_id = 0
for theline in sys.stdin:
	thisone = theline.strip().split(' ')

        match_id = int(thisone[Column.match_id])
	seconds = int(thisone[Column.seconds])
        if match_id != current_match_id:
                current_match_id = match_id
                next_row_at = 60
                assert seconds == 0

        if seconds < next_row_at:
                prevone = thisone
        else:
                while seconds >= next_row_at:
                        prevweight = float(seconds - next_row_at) / (seconds - int(prevone[Column.seconds]))
                        nowweight = 1.0 - prevweight
                        interpcol = list(thisone)
                        interpcol[Column.seconds] = next_row_at
                        for colnum in [8,9,10,11]:
                                interpcol[colnum] = int(nowweight * int(thisone[colnum]) + prevweight * int(prevone[colnum]))
                        print ' '.join([str(x) for x in interpcol])
                        next_row_at = next_row_at + 60
