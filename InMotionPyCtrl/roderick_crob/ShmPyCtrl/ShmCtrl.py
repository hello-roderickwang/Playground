#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Date    : 2019-09-26 15:41:25
# @Author  : Xuenan(Roderick) Wang
# @Email   : roderick_wang@outlook.com
# @GitHub  : https://github.com/hello-roderickwang

import ShmPy as shm

def is_torque_on():
    result = shm.send_command(shm.get_command('get', 'test_raw_torque'))
    print('type of result:', type(result), '\nresult:', result)

def set_torque_on():
    shm.send_command(shm.get_command('set', 'test_raw_torque', 1))

def send_torque(target, value=0):
    if is_torque_on is False:
        set_torque_on()
    else:
        if value > 3.45 or value < -3.45:
            value = 0
            print('VALUE OUT OF MAXIMUM RANGE!')
            print('VALUE RANGE: [-3.45, 3.45]')
        if target is 'upper':
            shm.send_command(shm.get_command('set', 'raw_torque_volts_s', value))
        elif target is 'lower':
            shm.send_command(shm.get_command('set', 'raw_torque_volts_e', value))
        else:
            print('WRONG TARGET!')

def get_position():
    pos = [0, 0]
    pos[0] = shm.send_command(shm.get_command('get', 'x')).stdout.decode('utf-8')
    pos[1] = shm.send_command(shm.get_command('get', 'y')).stdout.decode('utf-8')
    return pos

if __name__ == '__main__':
   is_torque_on()
