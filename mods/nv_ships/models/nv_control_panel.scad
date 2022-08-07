rotate(-90, [1, 0, 0]) {
    difference() {
        cube([1, 1, 1], center = true);
        translate([0, 8/16, 8/16])
            cube([12/16, 14/16, 6/16], center = true);
        
        translate([0, 8/16, 8/16])
            cube([20/16, 8/16, 6/16], center = true);
    }

    translate([-4/16, 2/16, 5/16])
        cube([1/16, 1/16, 1/16]);

    translate([-4/16, 4/16, 5/16])
        cube([1/16, 1/16, 1/16]);

    translate([-4/16, 6/16, 5/16])
        cube([1/16, 1/16, 1/16]);
}