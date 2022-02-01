// The percussive sound of footsteps on a stone floor
// Has a noise band from 100 - 300 Hz, with a sudden gain drop early on

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
0.02::second => env.duration;
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
