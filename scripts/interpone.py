#!/Users/david/local/bin/python

import sys

studytime = int(sys.argv[1])
for theline in sys.stdin:
	thisone = theline.strip().split(' ')
	seconds = int(thisone[7])
        if seconds < studytime:
                prevone = thisone
        if prevone is not None and seconds > studytime:
		prevweight = float(seconds - studytime) / (seconds - int(prevone[7]))
                nowweight = 1.0 - prevweight
                interpcol = list(thisone)
		for colnum in [8,9,10,11]:
			interpcol[colnum] = nowweight * int(thisone[colnum]) + prevweight * int(prevone[colnum])
		print ' '.join([str(x) for x in interpcol])
                prevone = None
