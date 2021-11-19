# Sounds

The audio files in this directory were automatically generated using the script
`record.sh`, which reads the `.ck` files in the same directory. These files are
written in the ChucK audio programming language, and you can edit them to modify
those sounds. The script is meant to be run in a Unix-like environment.

Basically, it runs ChucK with each input file, plus `compose.ck`, which contains
their common audio logic, and `rec.ck`, which saves the audio as a WAV file.
Then, FFMPeg is used to convert these into OGG Vorbis files suitable for
Minetest.
