// The sound of a rocket ship quickly jumping into the air
// Has an initial noise and a noisy tone hastily sweeping down

// communication
public class Global {
    static dur duration;
}

1.5::second => Global.duration;

// patch
Noise noise => Gain initial_gain => LPF low => dac;
noise => TwoPole two_sweep => Gain gain_sweep => dac;

// parameters
10 => initial_gain.gain;
500 => low.freq;
0.99 => two_sweep.radius;
1800 => two_sweep.freq;
0.02 => gain_sweep.gain;

// control loop
now + Global.duration => time end;
while(now < end - 1::second) {
    initial_gain.gain() * 0.7 => initial_gain.gain;
    two_sweep.freq() * 0.95 => two_sweep.freq;
    0.1::second => now;
}
0 => initial_gain.gain;
while(now < end) {
    two_sweep.freq() * 0.9 => two_sweep.freq;
    gain_sweep.gain() * 0.7 => gain_sweep.gain;
    0.1::second => now;
}
