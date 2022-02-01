// The sound of footsteps on tiny rock fragments (variant)
// Has a noise band from 150 - 1300 Hz

// communication
public class Global {
    static dur duration;
}

0.25::second => Global.duration;

// patch
Noise noise => LPF low => HPF high => Envelope env => dac;

// parameters
1300 => low.freq;
150 => high.freq;
0.05::second => env.duration;
env.keyOn();

// control loop
now + Global.duration => time end;
true => int env_key;
while(now < end) {
    0.1::second => now;
    if(end - now < 0.10::second & env_key) {
        false => env_key;
        0.10::second => env.duration;
        env.keyOff();
    }
}
