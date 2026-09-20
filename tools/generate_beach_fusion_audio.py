"""Original bounded sea fusion cues; rerun without touching other audio."""
import math, random
from generate_beach_audio import save, RATE
for n, name in enumerate(['pearl_wave','bubble_aquarium','crab_udon']):
    rng=random.Random(220+n)
    samples=[]
    for i in range(int(RATE*.65)):
        t=i/RATE
        if n==0:
            env=math.sin(math.pi*t/.65)**2
            value=env*(.13*math.sin(math.tau*330*t)+.18*(rng.random()-.5))
        elif n==1:
            a=t%.16
            value=.25*math.exp(-a*24)*math.sin(math.tau*(600*a+1100*a*a))*max(0,1-t/.65)
        else:
            value=.20*math.exp(-t*9)*math.sin(math.tau*(280*t-100*t*t))
            if t>.35: value+=.22*math.exp(-(t-.35)*45)*(rng.random()-.5)
        samples.append(value)
    save(name,samples)
