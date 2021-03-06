// The sound of footsteps on coarse regolith
// Has a noise band from 500 - 1800 Hz

// communication
public class Global {
    static dur duration;
}

0.25::second => Global.duration;

// patch
Noise noise => LPF low => HPF high => Envelope env => dac;

// parameters
1800 => low.freq;
500 => high.freq;
0.07::second => env.duration;
env.keyOn();

// control loop
now + Global.duration => time end;
true => int env_key;
while(now < end) {
    0.1::second => now;
    if(end - now < 0.2::second & env_key) {
        false => env_key;
        0.15::second => env.duration;
        env.keyOff();
    }
}
