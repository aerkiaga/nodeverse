// The muffled sound of a rocket engine
// Has a peak at 200 Hz and low- and mid-frequency noise

// communication
public class Global {
    static dur duration;
}

0.3::second => Global.duration;

// patch
Noise noise => Envelope env => LPF low => Gain gain => dac;

// parameters
0.1::second => env.duration;
300 => low.freq;
10 => gain.gain;

// control
0::second => env.duration;
env.keyOn();
0.1::second => now;
0.2::second => env.duration;
env.keyOff();
0.2::second => now;
