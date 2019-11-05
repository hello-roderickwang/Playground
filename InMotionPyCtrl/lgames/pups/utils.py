#!/usr/bin/python

# utilities for pups
# InMotion2 robot system software

# Copyright 2012-2014 Interactive Motion Technologies, Inc.
# Watertown, MA, USA
# http://www.interactive-motion.com
# All rights reserved

from __future__ import division, absolute_import, print_function  # Python 3

import matplotlib
matplotlib.use('agg')  # choose non-interactive backend. could also use cairo here
import Image
from pandas import DataFrame
from pylab import *
import os
import re
import shutil
from os.path import join as pjoin
from glob import glob
from collections import defaultdict
from subprocess import call
from ta import readImtLog
import errno
import yaml

PUPS_HOME = os.path.dirname(os.path.abspath(__file__))
north_cw_rose = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW']
east_ccw_rose = ['E', 'NE', 'N', 'NW', 'W', 'SW', 'S', 'SE']
ew_rose = ['E', 'W'] * 4
column_names = {'planar': ['i', 'x', 'y', 'vx', 'vy', 'fx', 'fy', 'fz', 'seg'],
                'planarhand': ['i', 'x', 'y', 'vx', 'vy', 'fx', 'fy', 'fz', 'seg', 'hp', 'hv', 'hmdf', 'hf'],
                'wrist': ['i', 'x', 'y', 'z', 'vx', 'vy', 'vz', 'fx', 'fy', 'fz', 'gr']}
angles = dict(zip(east_ccw_rose, linspace(0, 2 * pi - pi / 4, 8)))
Hz = 200.
plots_config = yaml.load(open(pjoin(PUPS_HOME, 'config/plots')))

DPI = 150
fig_width = 4
fig_height = fig_width
matplotlib.rcParams.update({'font.size': 14})


class rhash(defaultdict):
    """
    used like a dict except sub-dicts automagically created as needed
    """

    def __init__(self, *a, **b):
        #noinspection PyArgumentList
        defaultdict.__init__(self, rhash, *a, **b)

    def __repr__(self):
        return "rhash(%s)" % (repr(dict(self)),)


def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc:
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise


def dateify(date):
    return '-'.join((date[0:4], date[4:6], date[6:8])) + ' ' + date[9:12]


def parse_dir(dirname, globby, bkglob, pat, onewayrec=False):
    fn = latest_file(dirname, globby, bkglob)
    if not fn:
        return False
    pat = re.compile(pat)
    if onewayrec:
        (game, run, time) = pat.match(os.path.basename(fn)).groups()[0:3]
        return pjoin(dirname, '{}_{}_{}_'.format(game, run, time))
    else:
        (game, time) = pat.match(os.path.basename(fn)).groups()[0:2]
        return pjoin(dirname, '{}_{}_'.format(game, time))


def latest_file(dirname, globpattern, backupglobpattern):
    """
    Why are we getting both a globpattern and a backupglobpattern?
    Because we don't want the latest stem [group of files], we want the latest
    stem that is associated with a FULL group of files.
    Suppose the user starts a point-to-point and stops halfway, then runs it again
    and goes all the way. Then just "latest" would suffice.
    But suppose the user starts a point-to-point, does the whole thing, then does it
    again and doesn't complete it. Now the "latest" is wrong, and we want the full one.
    If there's no complete one at all, we just use the latest incomplete one.
    """

    globlist = glob(pjoin(dirname, globpattern))
    if not globlist:
        globlist = glob(pjoin(dirname, backupglobpattern))
        if not globlist:
            return False
    return globlist[-1]


def shoulder_dfr(filename):
    """
    take a filename for a shoulder file
    parse it into a dataframe
    """

    r = {}
    pat = re.compile('^sh(\w+)_(\d{6})_(\d).dat$')
    (
        r['game'],
        r['time'],
        r['num']
    ) = pat.match(os.path.basename(filename)).groups()
    d = DataFrame(readImtLog(filename), columns=column_names['planar'])
    r['maxfz'] = d.fz.max()
    r['minfz'] = d.fz.min()
    r['dfz'] = abs(r['maxfz'] - r['minfz'])

    return r, d


def circle_dfr(filename):
    """
    take a filename for a circle file
    parse it into a dataframe
    """

    r = {}
    pat = re.compile('^circle_([39])_(cc?w)_(\d{6})_(\d).dat$')
    (
        r['ew'],
        r['chi'],
        r['time'],
        r['num']
    ) = pat.match(os.path.basename(filename)).groups()
    d = DataFrame(readImtLog(filename), columns=column_names['planar'])
    return r, d


def pbs_dfr(filename, robot='planar'):
    """
    take a filename for a PBS file
    parse it into a dataframe
    compute octants
    """

    r = {}
    pat = re.compile('^\w+_(\d{6})_multi.dat$')
    r['time'] = pat.match(os.path.basename(filename)).groups()[0]
    (data, fields) = readImtLog(filename, getFields=True)
    d = DataFrame(data, columns=column_names[robot])
    if 'pathlength' in fields:
        r['pathlength'] = float(fields['pathlength'])
    d['hypot'] = hypot(d.x, d.y)
    d['octant'] = vectorize(octant)(d.x, d.y)
    return r, d


def compass_dfr(filename, robot='planar', mincutoff=0.1, dimension='2d'):
    """
    take a filename for a compass-based file
    parse it into a dataframe
    add vel and dsl columns for good measure
    return dataframe and r dict
    """

    r = {}
    pat = re.compile('^(\w+)_(\d{6})_([SN]*[WE]?)([bt])(\d+).dat$')
    (
        r['game'],
        r['time'],
        r['compass'],
        r['bt'],
        r['num']
    ) = pat.match(os.path.basename(filename)).groups()

    (data, fields) = readImtLog(filename, getFields=True)
    d = DataFrame(data, columns=column_names[robot])
    if 'pathlength' in fields:
        r['pathlength'] = float(fields['pathlength'])

    d['dsl'] = cdsl(r['compass'], d.x, d.y)

    if dimension == '2d':
        d['vel'] = hypot(d.vx, d.vy)
    else:
        d['vel'] = abs(d.vz)

    r['max_vel'] = d.vel.max()
    r['minvel'] = r['max_vel'] * mincutoff

    return r, d


def target_point(compass, pathlen, robot='planar', dimension='2d'):
    """
    What are the coordinates of the point the patient is attempting to reach?
    """

    if dimension == 'ps':  # robot == wrist is implied
        psdist = 0.557
        return {'E': (psdist, 0), 'W': (-psdist, 0)}[compass]
    if robot == 'wrist':
        northeastX = 0.341  # 2013-08-22 got this from movebox actual value
        northeastY = northeastX / 2
        northY = northeastX / sqrt(2)
        eastX = northY * 2
        return {'N': (0, northY),
                'NE': (northeastX, northeastY),
                'E': (eastX, 0),
                'SE': (northeastX, -northeastY),
                'S': (0, -northY),
                'SW': (-northeastX, -northeastY),
                'W': (-eastX, 0),
                'NW': (-northeastX, northeastY)}[compass]
    else:  # planar - just a compass rose.
        return cos(angles[compass]) * pathlen, sin(angles[compass]) * pathlen


def octant(x, y):
    """
     given x, y return a compass octant from ROSE
    """

    def diff_angle(ang1, ang2):
        if ang1 < ang2:
            ang1, ang2 = ang2, ang1
        return min(ang1 - ang2, 360 - (ang1 - ang2))

    t = rad2deg(arctan2(y, x))
    if t < 0:
        t += 360
    diff_oct = array([diff_angle(t, i * 45) for i in range(8)])
    return east_ccw_rose[diff_oct.argmin()]


def fmt(x):
    try:
        return "{0:5.3f}".format(x)
    except:
        return NaN


def cdsl(compass, x, y):
    """
    compass distance to straight line
    calculate distance to the straight line from the 8 compass points
    NE and SW are / A=-1, B=1
    NW and SE are \ A=1, B=1
    use dsl for diagonal x cases
    factor out the + h/v cases
    to optimize and to avoid dividing by zero
    """

    def dsl(A, B, C, xx, yy):
        return abs((A * xx + B * yy + C) / sqrt(A ** 2 + B ** 2))

    if compass in ['N', 'S']:
        return abs(x)
    elif compass in ['E', 'W']:
        return abs(y)
    elif compass in ['NE', 'SW']:
        return dsl(-1, 1, 0, x, y)
    elif compass in ['NW', 'SE']:
        return dsl(1, 1, 0, x, y)
    else:
        raise TypeError('bad compass direction: ' + compass)


def is_cached(writepath, nocache):
    if nocache:
        return False
    if os.path.exists(writepath + '.gif') and os.path.getsize(writepath + '.gif') > 0:
        print('Output {} exists, skipping...'.format(os.path.basename(writepath)))
        return True
    else:
        return False


def save_gif(writepath, grayscale=True):
    """
    htmldoc has issues with pngs, but savefig doesn't understand gifs...
    """

    savefig(writepath + '.png', bbox_inches='tight', dpi=DPI)
    if grayscale:
        Image.open(writepath + '.png').convert('LA').save(writepath + '.gif')
    else:
        Image.open(writepath + '.png').save(writepath + '.gif')
    os.remove(writepath + '.png')


def write_plot_ps(data, writepath, nocache=False):
    """
    polar plot showing east-west max PS movements
    """

    if is_cached(writepath, nocache):
        return

    # noinspection PyUnusedLocal
    def rad_to_posrad(x, pos):
        if x > pi:
            x = 2*pi - x
        return ' {:.2f} '.format(x) if x <= pi/2 else ''

    fig = figure(figsize=(fig_width, fig_height))
    fig.set_figwidth(fig_width)
    ax = fig.add_subplot(1, 1, 1, projection='polar')

    numpairs = len(data['E'])

    # assemble the data. this could probably be done more concisely with a list comprehension
    d = []
    for i in arange(numpairs)+1:
        d.extend((-data['E'][i], data['W'][i]))

    bar(left=d, height=[1]*len(d), width=0, linewidth=0.33, color='k')
    maxE = max(data['E'].values())
    maxW = max(data['W'].values())

    ax.set_yticklabels([])
    #ax.grid(b=False)
    yticks([])
    ax.set_theta_zero_location('N')

    text(1.4, 0.75, 'max {:.2f}'.format(maxW), ha='center')
    text(2*pi - 1.4, 0.75, 'max {:.2f}'.format(maxE), ha='center')

    ylim([0, 1.1])
    ax.xaxis.set_major_locator(FixedLocator([0, 0.57, 2*pi-0.57]))
    ax.xaxis.set_major_formatter(FuncFormatter(rad_to_posrad))
    ax.yaxis.set_major_locator(NullLocator())
    save_gif(writepath)
    close(fig)


def write_plot(xl, yl, writepath, plottype='position', robot='planar', nocache=False, pathlength=0.14, noTargets=False):
    """
    x and y are LISTS of lists of points (we don't want to connect last of each with first of each)
    writes out a PNG plot

    if plottype is 'ps', then xl is actually the ps dimension and yl is timepoint
    """

    if is_cached(writepath, nocache):
        return

    targetpointsX = []
    targetpointsY = []
    for direction in north_cw_rose:
        x, y = target_point(direction, pathlength, robot)
        targetpointsX.append(x)
        targetpointsY.append(y)

    fig = figure(figsize=(fig_width, fig_height))
    fig.set_figwidth(fig_width)
    ax = fig.add_subplot(1, 1, 1)

    d = plots_config[plottype + robot]
    if 'axis' in d:
        axis(d['axis'])
    xlim(d['xlim'])
    ylim(d['ylim'])
    xlabel(d['xlabel'])
    ylabel(d['ylabel'])
    if d.get('axvline'):
        axvline(color='#AAAAAA')
    if d.get('axhline'):
        axhline(color='#AAAAAA')
    if d.get('invert'):
        ax.invert_yaxis()

    if plottype != 'ps':
        ax.xaxis.set_major_locator(MaxNLocator(4))
        ax.xaxis.set_minor_locator(MaxNLocator(8))
        ax.yaxis.set_major_locator(MaxNLocator(4))
        ax.yaxis.set_minor_locator(MaxNLocator(8))
    ax.grid(b=True, which='major')
    ax.grid(b=True, which='minor')
    hold(True)
    for i in range(len(xl)):
        ax.plot(xl[i], yl[i], color='k')
    if plottype == 'position' and not noTargets:
        plot(targetpointsX, targetpointsY, '.', markersize=10, markerfacecolor='0.5', markeredgecolor='0.5')
    save_gif(writepath)
    close(fig)


def write_progress_plot(data, ynorm, ylimit, writepath):
    fig = figure(figsize=(fig_width, fig_height))
    ax = fig.add_subplot(1, 1, 1)
    ax.bar(range(len(data)), data, linewidth=2, facecolor='#CCCCCC', align='center', ecolor='k', width=.65)
    axhline(y=ynorm, color='k', linestyle='--', linewidth=2)
    ax.spines['left'].set_position(('outward', 10))
    ax.spines['bottom'].set_position(('outward', 10))
    xticks(range(len(data)))
    ax.set_xticklabels(())
    ylim(0, ylimit)
    ax.yaxis.grid(True)
    save_gif(writepath)
    close(fig)


def write_no_data_plot(writepath):
    shutil.copyfile(pjoin(os.path.dirname(os.path.abspath(__file__)), 'whitepixel.png'), writepath + '.png')


def write_pdf(outpath_html, outpath_pdf, htmltext):
    open(outpath_html + '.html', 'w').write(htmltext)
    call('/usr/bin/htmldoc --compression=9 --outfile ' + outpath_pdf +
         '.pdf --quiet --bodyfont helvetica --textfont helvetica --webpage -t pdf ' +
         outpath_html + '.html', shell=True)
