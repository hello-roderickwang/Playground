#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Date    : 2019-11-18 16:23:21
# @Author  : Xuenan(Roderick) Wang
# @Email   : roderick_wang@outlook.com
# @GitHub  : https://github.com/hello-roderickwang

import ShmPyCtrl.ShmPy as shm
import subprocess

shm_path = './shm'

command = {
    'direction': 'null',
    'speed': 0,
    'start_pos': (0, 0),
    'end_pos': (0, 0)
}

def set_shm_path(path):
    shm_path = path

def start_rtl():
    subprocess.run(['tclsh ./start.tcl'], shell=True)

def wshm(target, value):
    shm.send_command(get_command(action='set', target=target, value=value, path=shm_path))

def set_default():
    wshm('no_safety_check', 1)
    wshm('stiff', 100)
    wshm('damp', 5)
    wshm('slot_max', 4)

def set_parameter(target, value):
    command[target] = value

def set_command(direction, speed, start_pos, end_pos):
    command['direction'] = direction
    command['speed'] = speed
    command['start_pos'] = start_pos
    command['end_pos'] = end_pos

def run_movebox():
    subprocess.run(['tclsh ./movebox.tcl '+command['direction']+' '+command['speed']+' '\
        +command['start_pos'][0]+' '+command['start_pos'][1]+' '+command['end_pos'][0]+' '\
        +command['end_pos'][1]], shell=Ture)

if __name__ == '__main__':
    start_rtl()
    set_default()
    set_command('left', 0.05, (0, 0), (0.3, 0))
    run_movebox()