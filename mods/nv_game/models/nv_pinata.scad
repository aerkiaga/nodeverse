module leg() {
    translate([-3/16, 4/16, -8/16])
        cube([2/16, 2/16, 6/16]);
}

module two_legs() {
    leg();
    mirror([1, 0, 0])
        leg();
}

module ear() {
    translate([-2/16, -3/16, 6/16])
        cube([1/16, 1/16, 2/16]);
}

rotate(-90, [1, 0, 0]) {
    two_legs();
    mirror([0, 1, 0])
        two_legs();
    translate([-1/16, 6/16, -3/16])
        cube([2/16, 2/16, 4/16]);
    translate([-1/16, 6/16, 1/16])
        cube([2/16, 1/16, 1/16]);
    translate([-3/16, -6/16, -2/16])
        cube([6/16, 12/16, 4/16]);
    translate([-2/16, -6/16, 2/16])
        cube([4/16, 4/16, 4/16]);
    ear();
    mirror([1, 0, 0])
        ear();
    translate([-2/16, -8/16, 4/16])
        cube([4/16, 2/16, 2/16]);
}