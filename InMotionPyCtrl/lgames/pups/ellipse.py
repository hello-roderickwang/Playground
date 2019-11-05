#!/usr/bin/python

# crunch performance data for circle
# InMotion2 robot system software

# Copyright 2012-2014 Interactive Motion Technologies, Inc.
# Watertown, MA, USA
# http://www.interactive-motion.com
# All rights reserved

from __future__ import division, absolute_import, print_function  # Python 3

from utils import *
from pylab import *
from glob import glob
import warnings

warnings.simplefilter("ignore", ComplexWarning)  # don't warn about discarding imaginary part


def ell1(filename):
    r, d = circle_dfr(filename)
    d['bx'] = d.x - d.x.mean()
    d['by'] = d.y - d.y.mean()
    n = len(d)
    #noinspection PyCallingNonCallable
    m = dot(matrix(d[['bx', 'by']]).T, matrix(d[['bx', 'by']])) / n
    (e2, e1) = eig(m)[0]
    if e1 <= 0 or e2 <= 0:
        r['independence'] = 0
        r['circle_size'] = 0
    else:
        r['independence'] = float(sqrt(e1) / sqrt(e2))
        if r['independence'] > 1:
            r['independence'] **= -1
        r['circle_size'] = float(sqrt(e1 * e2) * 2 * pi)

    return r, d


def ell20(dirname):
    """
    crunch output from all circle files
    """

    clist = glob(os.path.join(dirname, 'circle*.dat'))

    v = {'independence': [],
         'circle_size': []}

    all_x = []
    all_y = []

    for fn in clist:
        if not os.path.exists(fn) or os.path.getsize(fn) < 500:
            continue

        r, d = ell1(fn)
        all_x.append(d.x)
        all_y.append(d.y)

        for m in v:
            v[m].append(r[m])

    means = {}
    for m in v:
        means[m] = mean(v[m])

    return means, all_x, all_y
