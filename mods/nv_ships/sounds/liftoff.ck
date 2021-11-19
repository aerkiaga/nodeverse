// The muffled sound of a rocket engine
// Has a peak at 200 Hz and low- and mid-frequency noise

// communication
public class Global {
    static dur duration;
}

5::second => Global.duration;

// patch
Noise noise => BPF band => OneZero zero => LPF low => dac;
noise => Gain initial_gain => LPF low2 => dac;
noise => TwoPole two_sweep => Gain gain_sweep => dac;

// parameters
200 => band.freq;
10 => band.Q;
0 => zero.b0;
10 => zero.b1;
1000 => low.freq;
10 => initial_gain.gain;
500 => low2.freq;
0.99 => two_sweep.radius;
1800 => two_sweep.freq;
0.02 => gain_sweep.gain;

// control loop
now + Global.duration => time end;
while(now < end - 4.5::second) {
    initial_gain.gain() * 0.7 => initial_gain.gain;
    two_sweep.freq() * 0.95 => two_sweep.freq;
    0.1::second => now;
}
while(now < end - 4::second) {
    two_sweep.freq() * 0.9 => two_sweep.freq;
    gain_sweep.gain() * 0.7 => gain_sweep.gain;
    0.1::second => now;
}
0 => gain_sweep.gain;
while(now < end) {
    0.1::second => now;
}
