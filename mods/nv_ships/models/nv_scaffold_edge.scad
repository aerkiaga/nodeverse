rotate(-90, [1, 0, 0]) {
    difference() {
        cube([1, 1, 1], center = true);
        for(i = [-4 : 4]) {
            translate([(3+i)/16, (3-i)/16, -9/16])
                cube([7/16, 7/16, 18/16]);
        }
    }
}