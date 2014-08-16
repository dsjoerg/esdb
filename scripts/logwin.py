#!/Users/david/local/bin/python

from scipy.stats import norm
import math
import matplotlib.pyplot as plt
import numpy as np
import numpy.lib.recfunctions
import scipy as sp
import sys

leaguenames = ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Master']
xcol = 'armylograt'
ycol = 'inclograt'

snaps = np.load("/Users/David/Dropbox/Daves_Docs/ggtracker/research/s2gs_20130215/snaps.npy")
print "Input file loaded"

subsnap = dict()
for second in np.arange(5,21) * 60:
	subsnap[second] = snaps[snaps['seconds'] == second]
print "Subsnaps arranged"

plt.rc('font', size=5)
for second in np.arange(5,21) * 60:
	for docounts in [True, False]:
	        print "Doing {}".format(second)
	        fig = plt.figure(figsize=(8,6), dpi=100)
	        fig.subplots_adjust(top=0.85, bottom=0.05)
	        plt.figtext(0.5, 0.965, "{} vs {} {}".format(xcol, ycol, 'Count' if docounts else 'Win %'), ha="center")
		fignum=1
	        for league in range(0,6):
	                plt.subplot(2,3,fignum)
	                fignum=fignum+1
	                leaguesnap = subsnap[second]['trueleague'] == league
	                snapnow = subsnap[second][leaguesnap]
	                xvals = np.clip(np.log(np.cast[float](snapnow['army1'])/(snapnow['army2'] + 1.0)),-2.0,2.0)
	                yvals = np.clip(np.log(np.cast[float](snapnow['income1'])/(snapnow['income2'] + 1.0)),-2.0,2.0)
	                xdesc = sp.stats.describe(xvals)
	                ydesc = sp.stats.describe(yvals)
	                xmin = xdesc[2] - 3.0 * math.sqrt(xdesc[3])
	                ymin = ydesc[2] - 3.0 * math.sqrt(ydesc[3])
	                xmax = xdesc[2] + 3.0 * math.sqrt(xdesc[3])
	                ymax = ydesc[2] + 3.0 * math.sqrt(ydesc[3])
                        C = None if docounts else snapnow['winner']
	                plt.hexbin(xvals, yvals, C, cmap=plt.cm.YlOrRd_r, gridsize=30, extent=(xmin,xmax,ymin,ymax), mincnt=50)
                        cb = plt.colorbar()
                        label = 'count' if docounts else 'winner'
                        cb.set_label(label)
	                plt.title(leaguenames[league])

	        plt.savefig("{}{}log{}_{}.pdf".format(xcol[0], ycol[0], 'count' if docounts else 'win', second))
