"""Original coral-shore and Octo loops; deterministic standard-library synthesis."""
import math, random, struct, wave
from pathlib import Path
RATE=22050
OUT=Path(__file__).resolve().parents[1]/'assets/audio'
def save(name, samples):
    with wave.open(str(OUT/(name+'.wav')), 'wb') as f:
        f.setparams((1,2,RATE,0,'NONE','not compressed'))
        f.writeframes(struct.pack('<%dh'%len(samples),*[int(max(-.95,min(.95,v))*32767) for v in samples]))
def music(name, phase=0):
    samples=[]; rng=random.Random(45)
    notes=[0,4,7,9,7,4,2,7] if name=='beach' else [0,3,7,10,7,3,2,-2]
    base=220 if name=='beach' else 146.832
    for i in range(RATE*48):
        t=i/RATE; beat=t/.5; k=int(beat); a=t%0.5
        chord=[0,5,3,7][(k//8)%4]
        f=base*2**((notes[k%8]+chord)/12)
        lead=.10*math.exp(-a*6)*(math.sin(math.tau*f*a)+.2*math.sin(math.tau*f*2.01*a))
        bass=.10*math.exp(-a*5)*math.sin(math.tau*(base/2)*2**(chord/12)*a)
        drum=.055*math.exp(-a*22)*math.sin(math.tau*(65*a-35*a*a))
        air=(rng.random()-.5)*.035*math.exp(-(t%.25)*35)
        upper=.055*math.exp(-(t%.25)*9)*math.sin(math.tau*f*2*(t%.25)) if phase else 0
        samples.append(lead+bass+drum+air+upper)
    save(name,samples)
def effect(name, n):
    rng=random.Random(n); samples=[]
    for i in range(int(RATE*.7)):
        t=i/RATE; f=[220,660,440,160][n]
        env=min(1,t/.02)*math.exp(-t*6)
        v=.22*env*math.sin(math.tau*(f*t+100*t*t))+.035*env*(rng.random()-.5)
        samples.append(v)
    save(name,samples)
if __name__=='__main__':
    music('beach'); music('octo'); music('octo_phase2',1)
    for n,name in enumerate(['tide','cleanse','sea_cast','sea_hit']): effect(name,n)
