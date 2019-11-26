#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Date    : Nov.26 2019
# @Author  : Xuenan(Roderick) Wang
# @Email   : roderick_wang@outlook.com
# @GitHub  : https://github.com/hello-roderickwang

import numpy as np
import matplotlib.pyplot as plt
import math
import random


class LIF:
    def __init__(self, input_current):
        # self.input_current = np.zeros(20)
        self.input_current = input_current
        self.dt = 0.01
        self.v_compute = np.zeros(20)
        self.v_array = np.zeros(20)
        self.fire_array = np.zeros(20)
        self.v_threshold = 3  # -10
        self.v_rest = 0  # -65
        # self.v_array[0] = self.v_rest
        # self.v_array[-1] = self.v_rest
        self.r_m = 1
        self.c_m = 10
        self.tau_m = self.r_m * self.c_m
        self.neuron_status = -1  # **-1 no status **0 not fire **1 fire
        self.output_current = np.zeros(20)
        self.current_amplify = 4.5
        self.fire_number = 0

    def start(self):
        # print('initial fire array:', self.fire_array)
        # print('initial v_array:', self.v_array)
        self.input_current = self.input_current * self.current_amplify
        self.v_array = np.zeros(len(self.input_current) * int(1 / self.dt))
        self.fire_array = np.zeros(len(self.v_array))
        self.output_current = np.zeros(len(self.input_current))
        count = 0
        for i in range(1, len(self.v_array)):
            v_difference = -1 * self.v_array[i - 1] + self.r_m * self.input_current[math.floor(i * self.dt)]
            self.v_array[i] = self.v_array[i - 1] + v_difference / self.tau_m * self.dt
            if self.v_array[i] >= self.v_threshold:
                # print('v_array[', i, '] is:', self.v_array[i])
                # print('v_array[i-1]:', self.v_array[i-1])
                self.v_array[i] = self.v_rest
                self.fire_array[i] = 1
                count += 1
            else:
                self.v_array[i]
        self.fire_number = count
        self.output_current = self.fire_array

    def plot(self):
        plt.plot(range(0, len(self.v_array)), self.v_array)
        plt.plot(range(0, len(self.fire_array)), self.fire_array, 'o')
        # input_plot = np.zeros(len(self.input_current)*int(1/self.dt))
        # for i in range(0, len(self.input_current)*int(1/self.dt), int(1/self.dt)):
        # 	input_plot[i] = 1
        # plt.plot(range(0, len(self.input_current)*int(1/self.dt)), input_plot, 'o')
        plt.xlabel('Simulate Time in ms')
        plt.ylabel('Membrane Potential in mv')
        plt.show()


if __name__ == '__main__':
    input_current = [1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 1]
    input_current = np.zeros(50)
    for i in range(0, len(input_current)):
        input_current[i] = random.randrange(0, 2000) / 1000
    print('input length:', len(input_current))
    print('input current:', input_current)
    lif = LIF(input_current)
    lif.start()
    lif.plot()
    print('final fire array:', lif.fire_array)
    print('final fire array:', lif.v_array)
