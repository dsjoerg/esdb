#!/Users/david/local/bin/python

import matplotlib.pyplot as plt
import numpy as np
import scipy as sp
from scipy.stats import norm
import numpy.lib.recfunctions
import math

leaguenames = ['Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Master']

snaps = np.load("/Users/David/Dropbox/Daves_Docs/ggtracker/research/s2gs_20130215/snaps.npy")

# snaps = np.loadtxt('/Users/David/Dropbox/Daves_Docs/ggtracker/research/s2gs_20130215/s2gs_stats_2.txt.fixed.interp', dtype=[('match_id','i8'), ('gateway','S3'), ('winner','i1'), ('average_league','i1'), ('summary_league','i1'), ('race1','S1'), ('race2','S1'), ('seconds','i4'), ('army1','i4'), ('army2','i4'), ('income1','i4'), ('income2','i4'), ('duration_seconds','i4')])
print "Input file loaded"
# trueleague = np.where(snaps['summary_league'] > -1, snaps['summary_league'], snaps['average_league'])
# snaps = np.lib.recfunctions.append_fields(snaps, 'trueleague', trueleague, 'i1')

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
                ydesc = sp.stats.describe(subsnap[second][leaguesnap]['army1'])
                xmin = 0
                ymin = 0
                xmax = xdesc[2] + 3.0 * math.sqrt(xdesc[3])
                ymax = ydesc[2] + 3.0 * math.sqrt(ydesc[3])
                plt.hexbin(subsnap[second][leaguesnap]['army1'], subsnap[second][leaguesnap]['army2'], cmap=plt.cm.YlOrRd_r, gridsize=30, extent=(0,xmax,0,ymax))
                plt.title(leaguenames[league])

        plt.savefig("army_correspondence_{}.pdf".format(second))
