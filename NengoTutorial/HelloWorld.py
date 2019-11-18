#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Date    : Nov.12 2019
# @Author  : Xuenan(Roderick) Wang
# @Email   : roderick_wang@outlook.com
# @GitHub  : https://github.com/hello-roderickwang

import nengo
import numpy as np

# net is a nengo object
# when creating a new object, it has to be within a with block
net = nengo.Network()
with net:
    # by default, nengo uses LIF neurons
    my_ensemble = nengo.Ensemble(n_neurons=40, dimensions=1)
    my_node = nengo.Node(output=0.5)
    sin_node = nengo.Node(output=np.sin)
    nengo.Connection(my_node, my_ensemble)
    # 2-dimentional example
    two_d_ensemble = nengo.Ensemble(n_neurons=80, dimensions=2)
    nengo.Connection(sin_node, two_d_ensemble[0])
    nengo.Connection(my_ensemble, two_d_ensemble[1])
    # function to be computed across the connection?
    square = nengo.Ensemble(n_neurons=40, dimensions=1)
    nengo.Connection(my_ensemble, square, function=np.square)

def product(x):
    return x[0]*x[1]

with net:
    product_ensemble = nengo.Ensemble(n_neurons=40, dimensions=1)
    nengo.Connection(two_d_ensemble, product_ensemble, function=product)
    # add probe
    # argument synapse defines the time constant on a causal low-pass filter
    two_d_probe = nengo.Probe(two_d_ensemble, synapse=0.01)
    product_probe = nengo.Probe(product_ensemble, synapse=0.01)

sim = nengo.Simulator(net)
sim.run(5.0)
print(sim.data[product_probe][-10:])