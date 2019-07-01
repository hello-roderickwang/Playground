#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# @Date    : 2019-07-01 14:40:16
# @Author  : Xuenan(Roderick) Wang
# @Email   : roderick_wang@outlook.com
# @Github  : https://github.com/hello-roderickwang

import numpy as np
import matplotlib.pyplot as plt
import nxsdk.api.n2a as nx
from nxsdk.utils.plotutils import plotRaster

class XOR:
    def __init__(self):
        self.weight = np.zeros((2, 4, 4), dtype=int)
        self.num_input = 2
        self.num_output = 2
        self.num_hidden = 4

    # Define network structure
    def set_up_network(self, turn_on_learning=True):
        net = nx.NxNet()

        # Define compartment prototype(all neurons are the same)
        comProto = nx.CompartmentPrototype(vThMant=100,
                                           compartmentCurrentDecay=4096,
                                           compartmentVoltageDecay=0)

        # Create compartment group for different layers
        inputGrp = net.createCompartmentGroup(size=self.num_input, prototype=comProto)
        hiddenGrp = net.createCompartmentGroup(size=self.num_hidden, prototype=comProto)
        outputGrp = net.createCompartmentGroup(size=self.num_output, prototype=comProto)

        # Create spike generator as teaching neurons
        inputGen = net.createSpikeGenProcess(numPorts=self.num_input)
        outputGen = net.createSpikeGenProcess(numPorts=self.num_output)

        # Define learning rule
        lr = net.createLearningRule(dw='2^-2*x1*y0 - 2^-2*y1*x0',
                                    x1Impulse=127,
                                    x1TimeConstant=10,
                                    y1Impulse=127,
                                    y1TimeConstant=10,
                                    tEpoch=4)

        # Define connection prototype
        if turn_on_learning is True:
            connProto = nx.ConnectionPrototype(enableLearning=1, learningRule=lr)
            connTeachingProto = nx.ConnectionPrototype(enableLearning=0)
        elif turn_on_learning is False:
            connProto = nx.ConnectionPrototype(enableLearning=0)
        else:
            print('ERROR! turn_on_learning can only be True or False.')

        # Create connections
        conn = []
        if turn_on_learning is True:
            conn.append(inputGen.connect(inputGrp, prototype=connTeachingProto, weight=255))
            conn.append(inputGrp.connect(hiddenGrp, prototype=connProto))
            conn.append(hiddenGrp.connect(outputGrp, prototype=connProto))
            conn.append(outputGen.connect(outputGrp, prototype=connTeachingProto, weight=255))
        elif turn_on_learning is False:
            conn.append(inputGrp.connect(hiddenGrp, prototype=connProto, weight=self.weight[0][0:self.num_input][0:self.num_hidden]))
            conn.append(hiddenGrp.connect(outputGrp, prototype=connProto, weight=self.weight[1][0:self.num_hidden][0:self.num_output]))
        else:
            print('ERROR! turn_on_learning can only be True or False.')

    def 

        


if __name__ == '__main__':