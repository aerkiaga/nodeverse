// The percussive sound of footsteps on a stone floor (variant)
// Has a noise band from 70 - 200 Hz, with a sudden gain drop early on

// communication
public class Global {
    static dur duration;
}

0.23::second => Global.duration;

// patch
Noise noise => LPF low => HPF high => Envelope env => dac;

// parameters
200 => low.freq;
70 => high.freq;
3.0 => dac.gain;
0.01::second => env.duration;
env.keyOn();

// control loop
now => time start;
now + Global.duration => time end;
while(now - start < 0.02::second) {
    0.01::second => now;
}

100 => low.freq;
1.0 => dac.gain;
0.2::second => env.duration;
env.keyOff();

while(now < end) {
    0.01::second => now;
}
