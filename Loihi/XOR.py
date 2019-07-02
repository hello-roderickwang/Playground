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
        self.runTime = 80
        self.num_input = 2
        self.num_output = 1
        self.num_hidden = 4

    # Define network structure
    def set_up_network(self, turn_on_learning=True):
        net = nx.NxNet()

        # Define compartment prototype(all neurons are the same)
        comProto = nx.CompartmentPrototype(vThMant=100,
                                           compartmentCurrentDecay=4096,
                                           compartmentVoltageDecay=0)

        # Create compartment group for different layers
        comGrp = {}
        comGrp['inputGrp'] = net.createCompartmentGroup(size=self.num_input, prototype=comProto)
        comGrp['hiddenGrp'] = net.createCompartmentGroup(size=self.num_hidden, prototype=comProto)
        comGrp['outputGrp'] = net.createCompartmentGroup(size=self.num_output, prototype=comProto)

        # Create spike generator as teaching neurons
        comGrp['inputGen'] = net.createSpikeGenProcess(numPorts=self.num_input)
        comGrp['outputGen'] = net.createSpikeGenProcess(numPorts=self.num_output)

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
        conn = {}
        if turn_on_learning is True:
            conn['inputGen_inputGrp'] = comGrp['inputGen'].connect(comGrp['inputGrp'], prototype=connTeachingProto, weight=255)
            conn['inputGrp_hiddenGrp'] = comGrp['inputGrp'].connect(comGrp['hiddenGrp'], prototype=connProto)
            conn['hiddenGrp_outputGrp'] = comGrp['hiddenGrp'].connect(comGrp['outputGrp'], prototype=connProto)
            conn['outputGen_outputGrp'] = comGrp['outputGen'].connect(comGrp['outputGrp'], prototype=connTeachingProto, weight=255)
        elif turn_on_learning is False:
            conn['inputGrp_hiddenGrp'] = comGrp['inputGrp'].connect(comGrp['hiddenGrp'], prototype=connProto, weight=self.weight[0][0:self.num_input][0:self.num_hidden])
            conn['hiddenGrp_outputGrp'] = comGrp['hiddenGrp'].connect(comGrp['outputGrp'], prototype=connProto, weight=self.weight[1][0:self.num_hidden][0:self.num_output])
        else:
            print('ERROR! turn_on_learning can only be True or False.')

        return net, comGrp, conn

    # Define probes
    def set_up_probe(self, comGrp, conn):
        probe = {}
        probe['inputGrpS'] = comGrp['inputGrp'].probe(nx.ProbeParameter.SPIKE)
        probe['inputGrpU'] = comGrp['inputGrp'].probe(nx.ProbeParameter.COMPARTMENT_CURRENT)
        probe['inputGrpV'] = comGrp['inputGrp'].probe(nx.ProbeParameter.COMPARTMENT_VOLTAGE)
        probe['outputGrpS'] = comGrp['outputGrp'].probe(nx.ProbeParameter.SPIKE)
        probe['outputGrpU'] = comGrp['outputGrp'].probe(nx.ProbeParameter.COMPARTMENT_CURRENT)
        probe['outputGrpV'] = comGrp['outputGrp'].probe(nx.ProbeParameter.COMPARTMENT_VOLTAGE)
        probe['weight_1'] = conn['inputGrp_hiddenGrp'].probe(nx.ProbeParameter.SYNAPSE_WEIGHT)
        probe['weight_2'] = conn['hiddenGrp_outputGrp'].probe(nx.ProbeParameter.SYNAPSE_WEIGHT)
        return probe

    def save_weight(self, conn):
        self.weight[0] = conn['inputGrp_hiddenGrp'].weight
        self.weight[1] = conn['hiddenGrp_outputGrp'].weight

    def run(self):
        net, comGrp, conn = self.set_up_network(turn_on_learning=True)
        comGrp['inputGen'].addSpikes([0, 1], [[15, 20, 35, 40, 55, 60, 75, 80],
                                              [10, 20, 30, 40, 50, 60, 70, 80]])
        comGrp['outputGen'].addSpikes(0, [10, 15, 30, 35, 50, 55, 70, 75])
        probeLrn = self.set_up_probe(comGrp, conn)
        net.run(self.runTime)
        net.disconnect()
        self.save_weight(conn)

        net, comGrp, conn = self.set_up_network(turn_on_learning=False)
        probeNonLrn = self.set_up_probe(comGrp, conn)
        net.run(self.runTime/4)
        net.disconnect()

        plt.figure(1, figsize=(18, 10))
        plt.subplot(2, 1, 1)
        probeNonLrn['inputGrpS'].plot()
        plt.title('Input spikes')
        plt.subplot(2, 1, 2)
        probeNonLrn['outputGrpS'].plot()
        plt.title('Output spikes')

        plt.tight_layout()
        plt.show()

if __name__ == '__main__':
    snn_xor = XOR()
    snn_xor.run()