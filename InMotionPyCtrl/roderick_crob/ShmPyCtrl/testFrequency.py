#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Date    : 2019-09-27 15:30:31
# @Author  : Xuenan(Roderick) Wang
# @Email   : roderick_wang@outlook.com
# @GitHub  : https://github.com/hello-roderickwang

import ShmPy as shm
import time

if __name__ == '__main__':
    list_get = []
    time_start = time.clock()
    for i in range(100):
        list_get.append(shm.send_command(shm.get_command(action='get',target='x')))
    time_end = time.clock()
    print('For each get operation, time is:', (time_end-time_start)/100)
    print('For each get operation, frequency is:', 100/(time_end-time_start))
    list_set = []
    time_start = time.clock()
    for i in range(100):
        list_set.append(shm.send_command(shm.get_command(action='set',target='test_raw_torque',value=1)))
    time_end = time.clock()
    print('For each set operation, time is:', (time_end-time_start)/100)
    print('For each set operation, frequency is:', 100/(time_end-time_start))
    shm.send_command(shm.get_command(action='set',target='test_raw_torque',value=0))
