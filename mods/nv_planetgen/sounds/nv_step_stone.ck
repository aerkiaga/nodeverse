// The muffled sound of a rocket engine
// Has a peak at 200 Hz and low- and mid-frequency noise

// communication
public class Global {
    static dur duration;
}

0.2::second => Global.duration;

// patch
Noise noise => LPF low => HPF high => Envelope env => dac;

// parameters
300 => low.freq;
100 => high.freq;
3.0 => dac.gain;
0::second => env.duration;
env.keyOn();

// control loop
now => time start;
now + Global.duration => time end;
while(now - start < 0.02::second) {
    0.01::second => now;
}

200 => low.freq;
1.0 => dac.gain;
0.17::second => env.duration;
env.keyOff();

while(now < end) {
    0.01::second => now;
}
