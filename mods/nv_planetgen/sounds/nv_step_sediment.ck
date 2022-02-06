// The prolonged sound of footsteps on sand
// Has a noise band from 1000 - 4000 Hz

// communication
public class Global {
    static dur duration;
}

0.32::second => Global.duration;

// patch
Noise noise => LPF low => HPF high => Envelope env => dac;

// parameters
5800 => low.freq;
1000 => high.freq;
0.07::second => env.duration;
env.keyOn();

// control loop
now + Global.duration => time end;
true => int env_key;
while(now < end) {
    0.1::second => now;
    if(end - now < 0.22::second & env_key) {
        false => env_key;
        0.22::second => env.duration;
        env.keyOff();
    }
}
