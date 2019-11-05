#!/usr/bin/python

# crunch performance data for round_dynamic
# InMotion2 robot system software

# Copyright 2012-2014 Interactive Motion Technologies, Inc.
# Watertown, MA, USA
# http://www.interactive-motion.com
# All rights reserved

from __future__ import division, absolute_import, print_function  # Python 3

from utils import *
from pylab import *
import os


def rd1(filename, pathlen_from_is_file=0.14, robot='planar', dimension='2d'):
    r, d = compass_dfr(filename, robot=robot, dimension=dimension)
    if 'z' in d.keys():
        r['zmax'] = d.z.max()
    r['reach_error'] = 0
    r['pathlength'] = r.get('pathlength', pathlen_from_is_file)

    if r['bt'] == 't':
        (tx, ty) = target_point(r['compass'], r['pathlength'], robot=robot, dimension=dimension)
        if dimension == '2d':
            r['reach_error'] = hypot((tx - d.x), (ty - d.y)).min()
            r['disp'] = hypot(tx, ty) - r['reach_error']
        else:
            r['reach_error'] = abs(tx - d.z).min()  # tx is really tz
            r['disp'] = abs(tx) - r['reach_error']

    return r, d


def rd8(dirname, pathlen_from_is_file=0.14, robot='planar', dimension='2d'):
    """
    crunch output from 80 runs of rd1
    """

    pat = '^(\w+)_(\d{6})_([SN]*[WE]?)([bt])(\d+).dat$'
    if robot == 'wrist':
        if dimension == '2d':
            base = parse_dir(dirname, 'wr_round*_2d*NWb40.dat', 'wr_round*2d*.dat', pat)
        else:
            base = parse_dir(dirname, 'wr_round*_ps*Wb2.dat', 'wr_round*ps*.dat', pat)
    else:
        base = parse_dir(dirname, 'round*NWb40.dat', 'round*.dat', pat)

    if not base:
        return False

    v = rhash()
    all_x = []
    all_y = []
    all_z = []
    means = rhash()
    r = rhash()

    ROSE = north_cw_rose if dimension == '2d' else ['E', 'W']

    for i, direction in enumerate(ROSE):
        fn = base + direction + 't' + str(i + 1) + '.dat'

        if not os.path.exists(fn) or os.path.getsize(fn) < 500:
            continue

        r, d = rd1(fn, pathlen_from_is_file=pathlen_from_is_file, robot=robot, dimension=dimension)
        all_x.append(d.x)
        all_y.append(d.y)
        if 'z' in d.keys():
            all_z.append(d.z)

        if dimension == 'ps':
            v[direction][int(i / 2 + 1)] = d.z.max() if direction == 'E' else -d.z.min()

        v['reach_error'][direction] = r['reach_error']
        v['disp'][direction] = r['disp']

    for m in v:
        means[m] = mean(v[m].values())
    v['displacement'] = mean(v['disp'].values())
    # return pathlength so we have it to pass to the plotter. it doesn't really belong in v.
    v['pathlength'] = r['pathlength']

    return v, all_x, all_y, all_z
