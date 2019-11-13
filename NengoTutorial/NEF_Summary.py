#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Date    : Nov.12 2019
# @Author  : Xuenan(Roderick) Wang
# @Email   : roderick_wang@outlook.com
# @GitHub  : https://github.com/hello-roderickwang

# %matplotlib inline
import matplotlib.pyplot as plt
import numpy as np
import nengo
from nengo.dists import Uniform
from nengo.processes import WhiteSignal
from nengo.utils.ensemble import tuning_curves
from nengo.utils.ipython import hide_input
from nengo.utils.matplotlib import rasterplot

def aligned(n_neurons, radius=0.9):
    intercepts = np.linspace(-radius, radius, n_neurons)
    encoders = np.tile([[1], [-1]], (n_neurons//2, 1))
    intercepts *= encoders[:, 0]
    return intercepts, encoders

# Principle 1: Representation
# Encoding
model = nengo.Network(label="NEF Summary")
with model:
    input = nengo.Node(lambda t: t*2-1)
    input_probe = nengo.Probe(input)

with nengo.Simulator(model) as sim:
    sim.run(1.0)

plt.figure()
plt.plot(sim.trange(), sim.data[input_probe], lw=2)
plt.title("input Signal")
plt.xlabel("Time (s)")
plt.xlim(0, 1)
# plt.show()

intercepts, encoders = aligned(8)
with model:
    A = nengo.Ensemble(
        8,
        dimensions=1,
        intercepts=intercepts,
        max_rates=Uniform(80, 100),
        encoders=encoders
    )

with nengo.Simulator(model) as sim:
    eval_points, activities = tuning_curves(A, sim)

plt.figure()
plt.plot(eval_points, activities, lw=2)
plt.xlabel("Input Signal")
plt.ylabel("Firing rate (Hz)")
# plt.show()

with model:
    nengo.Connection(input, A)
    A_spikes = nengo.Probe(A.neurons)

with nengo.Simulator(model) as sim:
    sim.run(1)

plt.figure()
ax = plt.subplot(1, 1, 1)
rasterplot(sim.trange(), sim.data[A_spikes], ax)
ax.set_xlim(0, 1)
ax.set_ylabel('Neuron')
ax.set_xlabel('Time (s)')
# plt.show()

# Decoding
model = nengo.Network(label="NEF Summary")
with model:
    input = nengo.Node(lambda t: t*2-1)
    input_probe = nengo.Probe(input)
    intercepts, encoders = aligned(8)
    A = nengo.Ensemble(
        8,
        dimensions=1,
        intercepts=intercepts,
        max_rates=Uniform(80, 100),
        encoders=encoders
    )
    nengo.Connection(input, A)
    A_spikes = nengo.Probe(A.neurons, synapse=0.01)

with nengo.Simulator(model) as sim:
    sim.run(1)

scale = 180
plt.figure()
for i in range(A.n_neurons):
    plt.plot(sim.trange(), sim.data[A_spikes][:, i]-i*scale)
plt.xlim(0, 1)
plt.ylim(scale*(-A.n_neurons+1), scale)
plt.ylabel("Neuron")
plt.yticks(
    np.arange(scale/1.8, (-A.n_neurons+1)*scale, -scale),
    np.arange(A.n_neurons)
)
# plt.show()

with model:
    A_probe = nengo.Probe(A, synapse=0.01)

with nengo.Simulator(model) as sim:
    sim.run(1)

plt.figure()
plt.plot(sim.trange(), sim.data[input_probe], label="Input Signal")
plt.plot(sim.trange(), sim.data[A_probe], label="Decoded estimate")
plt.legend(loc="best")
plt.xlim(0, 1)
# plt.show()

model = nengo.Network(label="NEF Summary")
with model:
    input = nengo.Node(lambda t: t*2-1)
    input_probe = nengo.Probe(input)
    A = nengo.Ensemble(30, dimensions=1, max_rates=Uniform(80, 100))
    nengo.Connection(input, A)
    A_spikes = nengo.Probe(A.neurons)
    A_probe = nengo.Probe(A, synapse=0.01)

with nengo.Simulator(model) as sim:
    sim.run(1)

plt.figure(figsize=(15, 3.5))
plt.subplot(1, 3, 1)
eval_points, activities = tuning_curves(A, sim)
plt.plot(eval_points, activities, lw=2)
plt.xlabel("Input Signal")
plt.ylabel("Firing rate (Hz)")

ax = plt.subplot(1, 3, 2)
rasterplot(sim.trange(), sim.data[A_spikes], ax)
plt.xlim(0, 1)
plt.xlabel("Time (s)")
plt.ylabel("Neuron")

plt.subplot(1, 3, 3)
plt.plot(sim.trange(), sim.data[input_probe], label="Input Signal")
plt.plot(sim.trange(), sim.data[A_probe], label="Decoded estimate")
plt.legend(loc="best")
plt.xlabel("Time (s)")
plt.xlim(0, 1)
# plt.show()

model = nengo.Network(label="NEF Summary")
with model:
    input = nengo.Node(WhiteSignal(1, high=5), size_out=1)
    input_probe = nengo.Probe(input)
    A = nengo.Ensemble(1000, dimensions=1, max_rates=Uniform(80, 100))
    nengo.Connection(input, A)
    A_spikes = nengo.Probe(A.neurons)
    A_probe = nengo.Probe(A, synapse=0.01)

with nengo.Simulator(model) as sim:
    sim.run(1)

plt.figure(figsize=(10, 3.5))
plt.subplot(1, 2, 1)
plt.plot(sim.trange(), sim.data[input_probe], label="Input Signal")
plt.plot(sim.trange(), sim.data[A_probe], label="Decoded estimate")
plt.legend(loc="best")
plt.xlabel("Time (s)")
plt.xlim(0, 1)

ax = plt.subplot(1, 2, 2)
rasterplot(sim.trange(), sim.data[A_spikes], ax)
plt.xlim(0, 1)
plt.xlabel("Time (s)")
plt.ylabel("Neuron")
plt.show()

# Principle 2: Transformation
