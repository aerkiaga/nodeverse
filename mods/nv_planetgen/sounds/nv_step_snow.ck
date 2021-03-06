// The sound of feet moving through snow
// Has a noise band from 400 - 2200 Hz

// communication
public class Global {
    static dur duration;
}

0.4::second => Global.duration;

// patch
Noise noise => LPF low => HPF high => Envelope env => dac;

// parameters
2200 => low.freq;
400 => high.freq;
0.07::second => env.duration;
env.keyOn();

// control loop
now + Global.duration => time end;
true => int env_key;
while(now < end) {
    0.1::second => now;
    if(end - now < 0.2::second & env_key) {
        false => env_key;
        0.2::second => env.duration;
        env.keyOff();
    }
}
