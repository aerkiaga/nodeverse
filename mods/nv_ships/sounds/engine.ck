// The muffled sound of a rocket engine
// Has a peak at 200 Hz and low- and mid-frequency noise

// communication
public class Global {
    static dur duration;
}

10::second => Global.duration;

// patch
Noise noise => BPF band => OneZero zero => LPF low => dac;

// parameters
200 => band.freq;
5 => band.Q;
0 => zero.b0;
10 => zero.b1;
1500 => low.freq;

// control loop
now + Global.duration => time end;
while(now < end) {
    0.1::second => now;
}
