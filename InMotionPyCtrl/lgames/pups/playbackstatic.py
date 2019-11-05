#!/usr/bin/python

# crunch performance data for playbackstatic
# InMotion2 robot system software

# Copyright 2012-2014 Interactive Motion Technologies, Inc.
# Watertown, MA, USA
# http://www.interactive-motion.com
# All rights reserved

from __future__ import division, absolute_import, print_function  # Python 3

from utils import *
from pylab import *


def pbs1(dirname, robot='planar', pathlen_from_is_file=0.14, dimension='2d'):
    if robot == 'wrist':
        pat = 'wr_playback_static_{}*.dat'.format(dimension)
    else:
        pat = 'playback_static*.dat'
    fn = latest_file(dirname, pat, pat)

    r, d = pbs_dfr(fn, robot=robot)
    r['pathlength'] = r.get('pathlength', pathlen_from_is_file)

    r['maxdir'] = []
    for direction in north_cw_rose:
        r['maxdir'].append(nan_to_num(d[d.octant == direction].hypot.max()))
    r['hold_deviation'] = mean(r['maxdir'])

    return r, d
