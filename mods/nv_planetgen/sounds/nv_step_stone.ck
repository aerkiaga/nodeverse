// The muffled sound of a rocket engine
// Has a peak at 200 Hz and low- and mid-frequency noise

// communication
public class Global {
    static dur duration;
}

0.1::second => Global.duration;

// patch
Noise noise => LPF low => HPF high => Envelope env => dac;

// parameters
500 => low.freq;
200 => high.freq;
3.0 => dac.gain;
0::second => env.duration;
env.keyOn();

// control loop
now => time start;
now + Global.duration => time end;
while(now < end) {
    0.01::second => now;
    if(now - start > 0.02::second) {
        300 => low.freq;
        1.0 => dac.gain;
        0.07::second => env.duration;
        env.keyOff();
    }
}
