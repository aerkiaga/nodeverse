# Performance profiling
**Planetgen** includes the functions `profile_start()` and `profile.end()` for
this purpose, both of which print performance events to *stderr*. The scripts
in this directory are provided to automate the process. All the following
commands assume a Unix-like environment.

First of all, open the terminal and navigate to the top-level directory of the
mod (the `planetgen/` directory). Then, type the following command:

`python3 perf/profile.py`

That will add profiling statements to all Lua files in that directory. Don't
worry, it will be undone later. Make sure that the profiling-enabled mod is
in a location where it can be played on your Minetest installation. If so, run
the following command:

`minetest 2>&1 | python3 perf/analyze.py`

Minetest will open, and let you play a game with this mod. Play for as long as
you want, perform the tasks which performance you are interested in... After
that, simply close Minetest.

The console now displays a table with all the information you're interested in.
For example:

```
NAME                            COUNT       AVERAGE     TOTAL       ...
mapgen_callback                 26          0.64 s      16.73 s     #######################
generate_planet_chunk           23          363.20 ms   8.35 s      ######################
new_area_callback               62          77.72 ms    4.82 s      ######################
pass_elevation                  23          110.36 ms   2.54 s      #####################
elevation_compute_craters       19031       23.92 us    455.19 ms   ##################
register_color_variants         15          3.30 ms     49.57 ms    ###############
gen_linear_sum                  19031       2.22 us     42.33 ms    ###############
register_base_floral_nodes      1           31.42 ms    31.42 ms    ##############
elevation_compute_cover_layer   10270       3.02 us     31.05 ms    ##############
gen_weighted                    10282       2.38 us     24.45 ms    ##############
register_liquid_nodes           1           11.40 ms    11.40 ms    #############
elevation_compute_node          22825       0.46 us     10.45 ms    #############
elevation_compute_soil_layer    10270       0.69 us     7.07 ms     ############
register_base_nodes             1           6.88 ms     6.88 ms     ############
pass_caves                      2           1.61 ms     3.22 ms     ###########
caves_gen_block                 24          120.79 us   2.90 ms     ###########
planet_from_mapping             24          78.79 us    1.89 ms     ##########
split_not_generated_boxes       10          160.60 us   1.61 ms     ##########
fnColorStone                    160         3.54 us     0.57 ms     #########
generate_planet_metadata        6           92.83 us    0.56 ms     #########
choose_planet_nodes_and_colors  6           76.67 us    460.00 us   ########
add_planet_mapping              1           233.00 us   233.00 us   #######
fnColorWaterRandom              48          4.75 us     228.00 us   #######
fnColorGrassRandom              96          2.14 us     205.00 us   #######
fnColorGrass                    144         1.33 us     191.00 us   #######
fnColorGrassNormal              48          3.38 us     162.00 us   #######
fnColorWater                    64          1.84 us     118.00 us   ######
register_icy_nodes              1           109.00 us   109.00 us   ######
caves_check_block               18          3.56 us     64.00 us    ######
fnColorWaterNormal              16          3.12 us     50.00 us    #####
caves_gen_side_opening_positions6           5.17 us     31.00 us    ####
register_on_not_generated       2           5.50 us     11.00 us    ###
caves_gen_side_openings         6           1.67 us     10.00 us    ###
caves_gen_volume_noise          6           0.83 us     5.00 us     ##
```

**NAME** is just the name of each function profiled. Next to it are various
performance statistics; **COUNT** is the number of times the function was
called, **AVERAGE** is the average time per call, and **TOTAL** is the total
amount of time spent in that function. Finally, on the right there is a visual
chart (logarithmic scale) of total time. In this example, we see that a good
target for optimization is the `elevation_compute_craters` function.

While the above command only prints the table to the console, it's also easy to
save it to a text file, like this:

`minetest 2>&1 | python3 perf/analyze.py > perf/out.txt`

Finally, after you are done with profiling, you can restore the code to its
initial state by running:

`python3 perf/unprofile.py`
