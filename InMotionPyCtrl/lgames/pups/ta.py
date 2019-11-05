#!/usr/bin/python

# convert binary data to ascii
# InMotion2 robot system software

# Copyright 2012-2015 Interactive Motion Technologies, Inc.
# Watertown, MA, USA
# http://www.interactive-motion.com
# All rights reserved

# convert binary doubles to ascii

from __future__ import division, absolute_import, print_function  # Python 3

import struct
import sys
import os
from pylab import *
import logging

LENGTH = 8
talogdir = '/tmp/talog'
if not os.path.exists(talogdir):
    os.makedirs(talogdir)

logging.basicConfig(filename=os.path.join(talogdir, 'ta{}.log'.format(os.getpid())), format='%(levelname)s: %(message)s', level=logging.INFO)


def readImtLog(filename, getFields=False):
    logging.info('{}: attempting to open'.format(filename))
    ret = []
    ready = False
    columns = 0
    fields = {'logversion': '1.0', 'logcolumns': '0'}  # defaults

    with open(filename, 'rb') as ff:
        while True:
            # process each key/value pair
            line = ff.readline().rstrip()
            if '####' in line:
                ready = True
                break

            if not line or line[0] != 's':
                # this is not a key/value pair
                continue

            # if we're here, then we're on a s line.
            (_, k, v) = line.split(None, 2)
            fields[k] = v

        columns += int(fields['logcolumns'])
        ascii = float(fields['logversion']) > 1

        if not (ready and columns):
            logging.critical('{}: Not a valid IMT log file.'.format(filename))
            raise ValueError

        try:
            while True:
                if ascii:
                    d = ff.readline()
                    if not d:
                        break
                    ret.append(d.split())
                else:
                    d = ff.read(LENGTH * columns)
                    if not d:
                        break
                    ret.append(struct.unpack('d' * columns, d))
        except struct.error:
            logging.critical('{}: Not a valid IMT log file.'.format(filename))
            raise ValueError

    try:
        if getFields:
            return array(ret).astype(float), fields
        else:
            return array(ret).astype(float)
    except ValueError as e:
        logging.critical('{}: Not a valid IMT log file: {}'.format(filename, e.message))
        raise ValueError

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print('Usage: {} <logfile>'.format(sys.argv[0]))
        exit(1)
    data, fields = readImtLog(sys.argv[1], getFields=True)
    try:
        for row in data:
            print(' '.join([str(x) for x in row]))
    except (ArithmeticError, ValueError):
        print('Not a valid IMT log file.')
        exit(1)

    # print(fields)
