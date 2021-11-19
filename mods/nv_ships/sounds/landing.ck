// The sound of an engine winding down
// Engine noise with a further two tones at perfect octave swiping down
// The higher tone is more spread out, while the lower tone is cleaner

// communication
public class Global {
    static dur duration;
}

5::second => Global.duration;

// patch
Noise noise => BPF band => OneZero zero => LPF low => dac;
noise => TwoPole two_sweep => Gain gain_sweep => dac;
noise => TwoPole two_sweep2 => Gain gain_sweep2 => dac;

// parameters
200 => band.freq;
10 => band.Q;
0 => zero.b0;
10 => zero.b1;
1000 => low.freq;
1800 => two_sweep.freq;
0.99 => two_sweep.radius;
0.02 => gain_sweep.gain;
900 => two_sweep2.freq;
1 => two_sweep2.radius;
0.0001 => gain_sweep2.gain;

// control loop
now + Global.duration => time end;
while(now < end - 2.5::second) {
    two_sweep.freq() * 0.99 => two_sweep.freq;
    two_sweep2.freq() * 0.99 => two_sweep2.freq;
    band.freq() * 0.99 => band.freq;
    0.1::second => now;
}
while(now < end) {
    two_sweep.freq() * 0.99 => two_sweep.freq;
    two_sweep2.freq() * 0.99 => two_sweep2.freq;
    gain_sweep.gain() * 0.92 => gain_sweep.gain;
    gain_sweep2.gain() * 0.96 => gain_sweep2.gain;
    0.1::second => now;
}
