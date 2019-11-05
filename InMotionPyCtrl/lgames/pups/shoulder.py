#!/usr/bin/python

# crunch performance data for shoulder
# InMotion2 robot system software

# Copyright 2012-2014 Interactive Motion Technologies, Inc.
# Watertown, MA, USA
# http://www.interactive-motion.com
# All rights reserved

from __future__ import division, absolute_import, print_function  # Python 3

from pylab import *
import os
from utils import *

SHOULDERTYPES = ('abduction', 'adduction', 'flexion', 'extension')


def sh5(dirname, shouldertype):
    """
    crunch output from 80 runs of rd1
    """
    if shouldertype not in SHOULDERTYPES:
        raise ValueError('invalid shoulder type {}'.format(shouldertype))

    base = parse_dir(dirname,
                    'shoulder_{}*_5.dat'.format(shouldertype),
                    'shoulder_{}*.dat'.format(shouldertype),
                    '^(\w+)_(\d{6})_(\d).dat$')

    if not base:
        return False

    v = {'dfz': []}
    all_t = []
    all_z = []

    for i in range(5):
        fn = base + str(i + 1) + '.dat'

        if not os.path.exists(fn):
            continue

        r, d = shoulder_dfr(fn)
        all_t.append(array(range(len(d.fz))) / Hz)
        all_z.append(d.fz)

        v['dfz'].append(r['dfz'])
    v['max_change_in_force'] = max(v['dfz'])

    return v, all_t, all_z
