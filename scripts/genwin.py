#!/Users/david/local/bin/python

from scipy.stats import norm
import math
import matplotlib.pyplot as plt
import numpy as np
import numpy.lib.recfunctions
import scipy as sp
import sys

xcol = sys.argv[1]
ycol = sys.argv[2]
leaguenames = ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Master']

snaps = np.load("/Users/David/Dropbox/Daves_Docs/ggtracker/research/s2gs_20130215/snaps.npy")
print "Input file loaded"

subsnap = dict()
for second in np.arange(5,21) * 60:
	subsnap[second] = snaps[snaps['seconds'] == second]
print "Subsnaps arranged"

plt.rc('font', size=5)
for second in np.arange(5,21) * 60:
        print "Doing {}".format(second)
        fig = plt.figure(figsize=(8,6), dpi=100)
        fig.subplots_adjust(top=0.85, bottom=0.05)
        plt.figtext(0.5, 0.965, "{} vs {}".format(xcol, ycol), ha="center")
	fignum=1
        for league in range(0,6):
                plt.subplot(2,3,fignum)
                fignum=fignum+1
                leaguesnap = subsnap[second]['trueleague'] == league
                snapnow = subsnap[second][leaguesnap]
                xdesc = sp.stats.describe(snapnow[xcol])
                ydesc = sp.stats.describe(snapnow[ycol])
                xmin = 0
                ymin = 0
                xmax = xdesc[2] + 3.0 * math.sqrt(xdesc[3])
                ymax = ydesc[2] + 3.0 * math.sqrt(ydesc[3])
                plt.hexbin(snapnow[xcol], snapnow[ycol], snapnow['winner'], cmap=plt.cm.YlOrRd_r, gridsize=30, extent=(0,xmax,0,ymax), mincnt=50)
                plt.title(leaguenames[league])

        plt.savefig("{}{}win_{}.pdf".format(xcol[0], ycol[0], second))
