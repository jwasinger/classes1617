#! /bin/python

import numpy as np
import matplotlib.pyplot as plt

X = np.linspace(-np.pi, np.pi, 256, endpoint=True)
C, S = np.cos(X), np.sin(X)

n_recur = [10, 15, 20, 30, 35]
time_recur = [0.01, 0.01, 0.01, 0.26, 2.89]

n_iter = [20000,30000,40000,50000,60000]
time_iter = [0.01, 0.01, 0.02, 0.03, 0.04]

fit_recur = np.polyfit(n_recur, time_recur, deg=3)
fit_iter = np.polyfit(n_iter, time_iter, deg=3)

plt.plot(n_recur, time_recur, 'ro')
plt.plot(n_iter, time_iter, 'bo')

plt.plot(fit_iter, color='green')
plt.plot(fit_recur, color='yellow')

plt.show()
