rotate(-90, [1, 0, 0]) {
    translate([0, 0, -2/16])
    difference() {
        cube([12/16, 12/16, 12/16], center = true);
        translate([0, 6/16, -3/16])
        cube([6/16, 2/16, 2/16], center = true);
    }
    translate([0, 0, 5/16])
    difference() {
        cube([4/16, 4/16, 2/16], center = true);
        cube([2/16, 2/16, 3/16], center = true);
    }
}