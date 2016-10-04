#! /bin/python

import numpy as np
import matplotlib.pyplot as plt
import time
import pdb

def fib_iter(n):
  fib = 0
  a = 1
  t = 0
  for k in range(1, n):
    t = fib + a
    a = fib
    fib = t
  return fib

def fib_recur(n):
 if n == 0:
   return 0
 elif n == 1:
   return 1
 else:
   return fib_recur(n-1) + fib_recur(n-2);

def compare_fib():
  n_vals = [5000, 10000, 20000, 30000, 40000, 50000]
  output = []

  for n in n_vals:
    start_time = time.clock()
    fib_iter(n)
    delta_time_iter = time.clock() - start_time

    start_time = time.clock()
    fib_recur(0)
    delta_time_recur = time.clock() - start_time 

    output.append({'n':n, 'time_iter': delta_time_iter, 'time_recur': delta_time_recur})
  
  return output

map 
output = compare_fib()
pdb.set_trace()

X = np.linspace(-np.pi, np.pi, 256, endpoint=True)
C, S = np.cos(X), np.sin(X)

plt.plot(X, C)
plt.plot(X, S)

plt.show()
