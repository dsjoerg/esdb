#!/Users/david/local/bin/python

import matplotlib.pyplot as plt
import numpy as np
import scipy as sp
from scipy.stats import norm
import numpy.lib.recfunctions
import math

resdir = '/Users/David/Dropbox/Daves_Docs/ggtracker/research/s2gs_20130215'
leaguenames = ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Master']

snaps = np.load("{}/snaps.npy".format(resdir))

subsnap = dict()
for second in np.arange(5,21) * 60:
	subsnap[second] = snaps[snaps['seconds'] == second]
print "Subsnaps arranged"

plt.rc('font', size=5)
for second in np.arange(5,21) * 60:
        print "Doing {}".format(second)
        plt.figure(figsize=(8,6), dpi=100)
	fignum=1
        for league in range(0,6):
                plt.subplot(2,3,fignum)
                fignum=fignum+1
                leaguesnap = subsnap[second]['trueleague'] == league
                xdesc = sp.stats.describe(subsnap[second][leaguesnap]['army1'])
                ydesc = sp.stats.describe(subsnap[second][leaguesnap]['income1'])
                xmin = 0
                ymin = 0
                xmax = xdesc[2] + 3.0 * math.sqrt(xdesc[3])
                ymax = ydesc[2] + 3.0 * math.sqrt(ydesc[3])
                plt.hexbin(subsnap[second][leaguesnap]['army1'], subsnap[second][leaguesnap]['income1'], cmap=plt.cm.YlOrRd_r, gridsize=30, extent=(0,xmax,0,ymax))
                plt.title(leaguenames[league])

        plt.savefig("{}/army_income_{}.pdf".format(resdir, second))
