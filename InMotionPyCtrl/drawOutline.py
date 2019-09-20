#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Date    : 2019-09-20 15:21:38
# @Author  : Xuenan(Roderick) Wang
# @Email   : roderick_wang@outlook.com
# @GitHub  : https://github.com/hello-roderickwang

import subprocess
from time import sleep

if __name__ == '__main__':
    movement = []
    movement.append(subprocess.run(["echo set test_raw_torque 1 | ./shm"], shell=True))
    sleep(3)
    movement.append(subprocess.run(["echo set raw_torque_volts_s 1 | ./shm"], shell=True))#s=1, e=0
    sleep(5)
    movement.append(subprocess.run(["echo set raw_torque_volts_e 1 | ./shm"], shell=True))#s=1, e=1
    sleep(5)
    movement.append(subprocess.run(["echo set raw_torque_volts_s -1 | ./shm"], shell=True))#s=0, e=1
    sleep(5)
    movement.append(subprocess.run(["echo set raw_torque_volts_e -1 | ./shm"], shell=True))#s=0, e=0
    sleep(5)
    movement.append(subprocess.run(["echo set raw_torque_volts_s 0 | ./shm"], shell=True))#s=0, e=1
    sleep(5)
    movement.append(subprocess.run(["echo set raw_torque_volts_e 0 | ./shm"], shell=True))#s=0, e=0
    sleep(5)
    movement.append(subprocess.run(["echo set test_raw_torque 0 | ./shm"], shell=True))
    sleep(3)
print(movement)