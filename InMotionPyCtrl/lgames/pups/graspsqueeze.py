#!/usr/bin/python

# crunch performance data for point to point
# InMotion2 robot system software

# Copyright 2014 Interactive Motion Technologies, Inc.
# Watertown, MA, USA
# http://www.interactive-motion.com
# All rights reserved

from __future__ import division, absolute_import, print_function  # Python 3

from utils import *


def graspsqueeze(filename, mincutoff=0.1):
    """
    crunch output from planarhand
    """

    d = DataFrame(readImtLog(filename), columns=column_names['planarhand'])
    d['hp'] = around(d['hp'], 6)
    d['hv'] = abs(d['hv'])
    d['seg'] = d['seg'].astype(int) - 1

    v = {'range': [], 'move_time': [], 'mean_vel': [], 'smoothness': [], 'opening': []}

    # for each individual segment...
    for seg in unique(d['seg']):
        # range of motion
        v['range'].append(d[d.seg == seg]['hp'].max() - d[d.seg == seg]['hp'].min())

        # trimmed to > .1 of speed (for the segment)
        maxvel = d[d.seg == seg]['hv'].max()
        minvel = maxvel * mincutoff
        where_moving = d[(d.hv > minvel) & (d.seg == seg)]
        if len(where_moving) > 0:
            started_moving_index = where_moving.first_valid_index()
            stopped_moving_index = where_moving.last_valid_index()
            trimmed = d[started_moving_index:stopped_moving_index]
            v['move_time'].append((stopped_moving_index - started_moving_index) / Hz)

        else:
            # they didn't move at all. it's just zeros. deal with it.
            trimmed = d[d.seg == seg]
            v['move_time'].append(nan)

        v['mean_vel'].append(trimmed['hv'].mean())
        v['smoothness'].append(v['mean_vel'][seg] / maxvel)
        v['opening'].append(bool(seg % 2))

    v_df = DataFrame(v)
    summary = {}
    for opening in (False, True):
        direction = 'opening' if opening else 'closing'
        summary[direction + '_' + 'move_time'] = v_df[v_df.opening == opening]['move_time'].mean()
        summary[direction + '_' + 'mean_vel'] = v_df[v_df.opening == opening]['mean_vel'].mean()
        summary[direction + '_' + 'smoothness'] = v_df[v_df.opening == opening]['smoothness'].mean()

    return d, v, summary


def spplot(filename):
    d = DataFrame(readImtLog(filename), columns=column_names['planarhand'])
    d['hp'] = around(d['hp'], 6)
    d['hv'] = abs(d['hv'])
    d['seg'] = d['seg'].astype(int) - 1
    for seg in unique(d['seg']):
        plot(d[d.seg == seg].i, d[d.seg == seg].hp)
    yticks([0.054, 0.055, 0.056, 0.058, 0.06, 0.062, 0.064, 0.065, 0.066, 0.068])
    grid('on')

# DEBUG

if __name__ == '__main__':
    import sys
    import pprint
    pp = pprint.PrettyPrinter()
    print(sys.argv[1])
    d,v,s = graspsqueeze(sys.argv[1])
    pp.pprint(v)
    pp.pprint(s)

