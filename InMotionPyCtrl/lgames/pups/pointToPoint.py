#!/usr/bin/python

# crunch performance data for point to point
# InMotion2 robot system software

# Copyright 2012-2014 Interactive Motion Technologies, Inc.
# Watertown, MA, USA
# http://www.interactive-motion.com
# All rights reserved

from __future__ import division, absolute_import, print_function  # Python 3

from utils import *
from pylab import *
import os


def ptp1(filename, robot='planar', pathlen_from_is_file=0.14, dimension='2d'):
    r, d = compass_dfr(filename, robot=robot, dimension=dimension)

    if not d[d.vel > r['minvel']].empty:
        r['started_moving_index'] = d[d.vel > r['minvel']].first_valid_index()
        r['stopped_moving_index'] = d[d.vel > r['minvel']].last_valid_index()
        trimmed = d[r['started_moving_index']:r['stopped_moving_index']]
        move_time = (r['stopped_moving_index'] - r['started_moving_index']) / Hz
        if move_time < 0.1 or trimmed.vel.max() < 0.01:  # either 0.01 m/s or rad/s, either way
            r['initiation_time'] = NaN
        else:
            r['initiation_time'] = r['started_moving_index'] / Hz
    else:
        # it's all the same velocity (presumably zero), so do not trim
        trimmed = d
        r['initiation_time'] = NaN


    r['mean_vel'] = trimmed.vel.mean()
    r['path_error'] = trimmed.dsl.mean()
    r['smoothness'] = r['mean_vel'] / r['max_vel']
    r['pathlength'] = r.get('pathlength', pathlen_from_is_file)

    r['reach_error'] = 0
    if r['bt'] == 't':
        (tx, ty) = target_point(r['compass'], r['pathlength'], robot=robot, dimension=dimension)
        x, y = trimmed.x.irow(-1), trimmed.y.irow(-1)
        if dimension == '2d':
            r['reach_error'] = hypot((tx - x), (ty - y))
        else:
            r['reach_error'] = abs(tx - trimmed.z.irow(-1))  # tx is really tz, see target_point

    return r, d


def ptpmulti(dirname, robot='planar', pathlen_from_is_file=0.14, num=0, run=0, dimension='2d'):
    """
    crunch output from NUM runs of ptp1
    """

    if num not in (16, 20, 80):
        print('ptp called with wrong arguments')
        exit(1)

    wrist_ps = dimension == 'ps' and num == 20

    if num == 16:
        pat = '^(\w+)_(' + str(run) + ')_(\d{6})_([SN]*[WE]?)([bt])(\d+).dat$'
        if robot == 'wrist':
            base = parse_dir(dirname,
                             'wr_one*_{}_{}_*NWb8.dat'.format(dimension, run),
                             'wr_one*_{}_{}_*.dat'.format(dimension, run), pat, onewayrec=True)
        else:
            base = parse_dir(dirname,
                             'oneway_rec_{}*NWb8.dat'.format(run),
                             'oneway_rec_{}*.dat'.format(run), pat, onewayrec=True)
    else:
        pat = '^(\w+)_(\d{6})_([SN]*[WE]?)([bt])(\d+).dat$'
        if robot == 'wrist':
            base = parse_dir(dirname,
                             'wr_point*_{}*NWb40.dat'.format(dimension),
                             'wr_point*_{}*.dat'.format(dimension), pat)
        else:
            base = parse_dir(dirname,
                             'point*NWb40.dat',
                             'point*.dat', pat)

    if not base:
        return False

    ROSE = ew_rose if wrist_ps else north_cw_rose

    v = {'mean_vel': [],
         'max_vel': [],
         'path_error': [],
         'smoothness': [],
         'reach_error': [],
         'initiation_time': []}

    all_x = []
    all_y = []
    all_z = []
    means = rhash()
    r = rhash()

    for i in range(int(num / 2)):
        for bt in ('t', 'b'):
            direction = ROSE[i % 8]
            fn = base + direction + bt + str(i + 1) + '.dat'

            if not os.path.exists(fn) or os.path.getsize(fn) < 500:
                continue

            r, d = ptp1(fn, robot=robot, pathlen_from_is_file=pathlen_from_is_file, dimension=dimension)
            all_x.append(d.x)
            all_y.append(d.y)
            if dimension == 'ps' and 'z' in d.keys():
                all_z.append(d.z)

            if bt == 't' and wrist_ps:
                distance = d.z.max() if direction == 'E' else -d.z.min()
                means[direction][int(i / 2 + 1)] = abs(distance)

            for m in v:
                # append for all cases EXCEPT reach_error and initiation_time "b"s
                if not (m in ('reach_error', 'initiation_time') and r['bt'] == 'b'):
                    v[m].append(r[m])

    for m in v:
        means[m] = mean(array(v[m])[~isnan(v[m])])  # ignore any NaNs

    # return pathlength so we have it to pass to the plotter. it doesn't really belong in means.
    means['pathlength'] = r['pathlength']

    return means, all_x, all_y, all_z
