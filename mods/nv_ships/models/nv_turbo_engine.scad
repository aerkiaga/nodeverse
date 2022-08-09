module cyl(h, r, c) {
    difference() {
        cube([r, h, r], center = true);
        for(i = [0 : 90 : 360])
            rotate(i, [0, 1, 0])
                translate([r/2 - c/2, 0, r/2 - c/2])
                    cube([c, h, c], center = true);
    }
}

rotate(-90, [1, 0, 0]) {
    difference() {
        translate([0, 4/16, 0])
            cyl(8/16, 1, 2/16);
        translate([0, 7/16, 0])
            cyl(3/16, 10/16, 1/16);
    }
    difference() {
        translate([0, -4/16, 0])
            cyl(8/16, 12/16, 2/16);
        translate([0, -7/16, 0])
            cyl(3/16, 8/16, 1/16);
    }
}