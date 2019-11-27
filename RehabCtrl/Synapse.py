#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Date    : Nov.26 2019
# @Author  : Xuenan(Roderick) Wang
# @Email   : roderick_wang@outlook.com
# @GitHub  : https://github.com/hello-roderickwang


import Neurons
import numpy as np


class Synapse:
    def __init__(self, pre_neuron, post_neuron):
        self.pre_neuron = pre_neuron
        self.post_neuron = post_neuron
        self.weight = 0
        self.max_weight = 5
        self.min_weight = -5
        self.std_stimulate = 1
        self.type = ''  # 'excite' or 'inhibit'

    def set_weight(self, weight = 0):
        if weight == 0:
            self.weight = np.random.rand()
        else:
            self.weight = weight
        # make sure that weight is between max_weight and min_weight
        if self.weight > self.max_weight:
            self.weight = self.max_weight
        elif self.weight < self.min_weight:
            self.weight = self.min_weight
        # decide which kind of connection this is
        if self.weight > 0:
            self.type = 'excite'
        elif self.weight < 0:
            self.type = 'inhibit'
        else:
            self.type = ''
        self.check_weight()

    # set_weight() has to run before deliver()
    def deliver(self):
        if self.pre_neuron.is_firing is True:
            self.post_neuron.stimulate(self.std_stimulate*self.weight)

    def check_weight(self):
        if self.weight == 0:
            print('ERROR! Connection is not built. Weight is 0.')
        if self.type == '':
            print('ERROR! Unknown connection type.')

    def go(self):
        if self.weight == 0:
            self.set_weight()
        self.deliver()
