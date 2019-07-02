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
        self.weight_1 = np.ones((4, 2), dtype=int)
        self.weight_2 = np.ones((1, 4), dtype=int)
        self.runTime = 80
        self.num_input = 2
        self.num_output = 1
        self.num_hidden = 4

    # Define network structure
    def set_up_network(self, turn_on_learning=True):
        net = nx.NxNet()

        # Define compartment prototype(all neurons are the same)
        if turn_on_learning is True:
            comProto = nx.CompartmentPrototype(vThMant=10,
                                               compartmentCurrentDecay=4096,
                                               compartmentVoltageDecay=0,
                                               enableSpikeBackprop=1,
                                               enableSpikeBackpropFromSelf=1)
        elif turn_on_learning is False:
            comProto = nx.CompartmentPrototype(vThMant=10,
                                               compartmentCurrentDecay=4096,
                                               compartmentVoltageDecay=0)
        else:
            print('ERROR! turn_on_learning can only be True or False.')

        # Create compartment group for different layers
        comGrp = {}
        comGrp['inputGrp'] = net.createCompartmentGroup(size=self.num_input, prototype=comProto)
        comGrp['hiddenGrp'] = net.createCompartmentGroup(size=self.num_hidden, prototype=comProto)
        comGrp['outputGrp'] = net.createCompartmentGroup(size=self.num_output, prototype=comProto)

        # Create spike generator as teaching neurons
        comGrp['inputGen'] = net.createSpikeGenProcess(numPorts=self.num_input)
        comGrp['outputGen'] = net.createSpikeGenProcess(numPorts=self.num_output)

        # Define learning rule
        lr = net.createLearningRule(dw='2*x1*y0',
                                    x1Impulse=40,
                                    x1TimeConstant=4,
                                    y1Impulse=40,
                                    y1TimeConstant=4,
                                    tEpoch=2)

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
            conn['inputGen_inputGrp'] = comGrp['inputGen'].connect(comGrp['inputGrp'], prototype=connTeachingProto, weight=np.array([[255, 0], [0, 255]]))
            conn['inputGrp_hiddenGrp'] = comGrp['inputGrp'].connect(comGrp['hiddenGrp'], prototype=connProto, weight=np.ones((4, 2), dtype=int)*50)
            conn['hiddenGrp_outputGrp'] = comGrp['hiddenGrp'].connect(comGrp['outputGrp'], prototype=connProto, weight=np.ones((1, 4), dtype=int)*50)
            conn['outputGen_outputGrp'] = comGrp['outputGen'].connect(comGrp['outputGrp'], prototype=connTeachingProto, weight=np.array([255]))
        elif turn_on_learning is False:
            conn['inputGen_inputGrp'] = comGrp['inputGen'].connect(comGrp['inputGrp'], prototype=connProto, weight=np.array([[255, 0], [0, 255]]))
            conn['inputGrp_hiddenGrp'] = comGrp['inputGrp'].connect(comGrp['hiddenGrp'], prototype=connProto, weight=self.weight_1)
            conn['hiddenGrp_outputGrp'] = comGrp['hiddenGrp'].connect(comGrp['outputGrp'], prototype=connProto, weight=self.weight_2)
        else:
            print('ERROR! turn_on_learning can only be True or False.')

        return net, comGrp, conn

    # Define probes
    def set_up_probe(self, comGrp, conn):
        probe = {}
        probe['inputGrpS'] = comGrp['inputGrp'].probe(nx.ProbeParameter.SPIKE)[0]
        probe['inputGrpU'] = comGrp['inputGrp'].probe(nx.ProbeParameter.COMPARTMENT_CURRENT)[0]
        probe['inputGrpV'] = comGrp['inputGrp'].probe(nx.ProbeParameter.COMPARTMENT_VOLTAGE)[0]
        probe['outputGrpS'] = comGrp['outputGrp'].probe(nx.ProbeParameter.SPIKE)[0]
        probe['outputGrpU'] = comGrp['outputGrp'].probe(nx.ProbeParameter.COMPARTMENT_CURRENT)[0]
        probe['outputGrpV'] = comGrp['outputGrp'].probe(nx.ProbeParameter.COMPARTMENT_VOLTAGE)[0]
        probe['hiddenGrpS'] = comGrp['hiddenGrp'].probe(nx.ProbeParameter.SPIKE)[0]
        probe['hiddenGrpU'] = comGrp['hiddenGrp'].probe(nx.ProbeParameter.COMPARTMENT_CURRENT)[0]
        probe['hiddenGrpV'] = comGrp['hiddenGrp'].probe(nx.ProbeParameter.COMPARTMENT_VOLTAGE)[0]
        probe['weight_1'] = conn['inputGrp_hiddenGrp'].probe(nx.ProbeParameter.SYNAPSE_WEIGHT)[0][0]
        probe['weight_2'] = conn['hiddenGrp_outputGrp'].probe(nx.ProbeParameter.SYNAPSE_WEIGHT)[0][0]
        return probe

    def save_weight(self, conn):
        self.weight_1 = conn['inputGrp_hiddenGrp'].getConnectionState('weight')
        self.weight_2 = conn['hiddenGrp_outputGrp'].getConnectionState('weight')

    def run(self):
        net, comGrp, conn = self.set_up_network(turn_on_learning=True)
        comGrp['inputGen'].addSpikes([0, 1], [[15, 20, 35, 40, 55, 60, 75, 80],
                                              [10, 20, 30, 40, 50, 60, 70, 80]])
        comGrp['outputGen'].addSpikes(0, [10, 15, 30, 35, 50, 55, 70, 75])
        probeLrn = self.set_up_probe(comGrp, conn)
        net.run(85)
        net.disconnect()
        self.save_weight(conn)

        print('weight_1:\n', self.weight_1)
        print('weight_2:\n', self.weight_2)

        plt.figure(1, figsize=(18, 20))
        
        fig1 = plt.subplot(9, 1, 1)
        probeLrn['inputGrpU'].plot()
        plt.title('Input compartment current')
        fig1.set_xlim(0, 100)
        
        fig2 = plt.subplot(9, 1, 2)
        probeLrn['inputGrpV'].plot()
        plt.title('Input compartment voltage')
        fig2.set_xlim(fig1.get_xlim())
        
        fig3 = plt.subplot(9, 1, 3)
        probeLrn['inputGrpS'].plot()
        plt.title('Input spikes')
        fig3.set_xlim(fig1.get_xlim())

        fig4 = plt.subplot(9, 1, 4)
        probeLrn['hiddenGrpU'].plot()
        plt.title('Hidden compartment current')
        fig4.set_xlim(fig1.get_xlim())
        
        fig5 = plt.subplot(9, 1, 5)
        probeLrn['hiddenGrpV'].plot()
        plt.title('Hidden compartment voltage')
        fig5.set_xlim(fig1.get_xlim())
        
        fig6 = plt.subplot(9, 1, 6)
        probeLrn['hiddenGrpS'].plot()
        plt.title('Hidden spikes')
        fig6.set_xlim(fig1.get_xlim())
        
        fig7 = plt.subplot(9, 1, 7)
        probeLrn['outputGrpU'].plot()
        plt.title('Output compartment current')
        fig7.set_xlim(fig1.get_xlim())
        
        fig8 = plt.subplot(9, 1, 8)
        probeLrn['outputGrpV'].plot()
        plt.title('Output compartment voltage')
        fig8.set_xlim(fig1.get_xlim())
        
        fig9 = plt.subplot(9, 1, 9)
        probeLrn['outputGrpS'].plot()
        plt.title('Output spikes')
        fig9.set_xlim(fig1.get_xlim())

        plt.figure(2, figsize=(18, 20))

        Fig_w1 = plt.subplot(2, 1, 1)
        probeLrn['weight_1'].plot()
        plt.title('Weight 1')

        Fig_w2 = plt.subplot(2, 1, 2)
        probeLrn['weight_2'].plot()
        plt.title('Weight 2')
        Fig_w2.set_xlim(Fig_w1.get_xlim())

        plt.tight_layout()
        plt.show()

        net, comGrp, conn = self.set_up_network(turn_on_learning=False)
        comGrp['inputGen'].addSpikes([0, 1], [[15, 20],
                                              [10, 20]])
        probeNonLrn = self.set_up_probe(comGrp, conn)
        net.run(25)
        net.disconnect()

        plt.figure(3, figsize=(18, 20))
        
        fig1 = plt.subplot(9, 1, 1)
        probeNonLrn['inputGrpU'].plot()
        plt.title('Input compartment current')
        fig1.set_xlim(0, 100)
        
        fig2 = plt.subplot(9, 1, 2)
        probeNonLrn['inputGrpV'].plot()
        plt.title('Input compartment voltage')
        fig2.set_xlim(fig1.get_xlim())
        
        fig3 = plt.subplot(9, 1, 3)
        probeNonLrn['inputGrpS'].plot()
        plt.title('Input spikes')
        fig3.set_xlim(fig1.get_xlim())

        fig4 = plt.subplot(9, 1, 4)
        probeNonLrn['hiddenGrpU'].plot()
        plt.title('Hidden compartment current')
        fig4.set_xlim(fig1.get_xlim())
        
        fig5 = plt.subplot(9, 1, 5)
        probeNonLrn['hiddenGrpV'].plot()
        plt.title('Hidden compartment voltage')
        fig5.set_xlim(fig1.get_xlim())
        
        fig6 = plt.subplot(9, 1, 6)
        probeNonLrn['hiddenGrpS'].plot()
        plt.title('Hidden spikes')
        fig6.set_xlim(fig1.get_xlim())
        
        fig7 = plt.subplot(9, 1, 7)
        probeNonLrn['outputGrpU'].plot()
        plt.title('Output compartment current')
        fig7.set_xlim(fig1.get_xlim())
        
        fig8 = plt.subplot(9, 1, 8)
        probeNonLrn['outputGrpV'].plot()
        plt.title('Output compartment voltage')
        fig8.set_xlim(fig1.get_xlim())
        
        fig9 = plt.subplot(9, 1, 9)
        probeNonLrn['outputGrpS'].plot()
        plt.title('Output spikes')
        fig9.set_xlim(fig1.get_xlim())

        plt.tight_layout()
        plt.show()

if __name__ == '__main__':
    snn_xor = XOR()
    snn_xor.run()