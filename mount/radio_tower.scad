// Radio tower topper for the radar station roof. Prints flat on its back, no supports.
//   part = "tower" : the tower. Print flat (as exported), 0.12-0.16 mm layers. Paint the bands
//                    red and white in the slicer (grooves mark the band edges), dishes white,
//                    lights red. Push a short piece of 1.75 mm filament into the top hole (whip).
//   part = "foot"  : glue to the roof behind the rooftop unit, left of the button slot; the
//                    tower's tab sits in its slot.
// 2D coordinates: x across, y up, y = 0 at the top of the foot.

tw_h = 75;            // lattice height
tw_b = 11.6;          // half-width at the base (the tab below stays 12.4 wide for the foot's slot)
tw_t = 3.0;           // half-width at the top
bays = 12;
TAB_W = 12.4;         // tab that sits in the foot's 12.8 mm slot
bay  = tw_h / bays;
function hw(y) = tw_b - (tw_b - tw_t) * y / tw_h;

// relief heights (mm above the bed)
H_LEG = 3.0;  H_BRACE = 2.0;  H_DECK = 2.6;  H_DISH = 3.2;  H_RADOME = 3.6;  H_PANEL = 2.8;

module bar(a, b, w) hull() { translate(a) circle(d = w, $fn = 20); translate(b) circle(d = w, $fn = 20); }

// ---------- structure ----------
module above_base() intersection() { children(); translate([-30, 0]) square([60, 200]); }   // nothing wider than the tab below y = 0
module legs2d() {
    above_base() {
        bar([-hw(0), 0], [-hw(tw_h), tw_h], 2.8);
        bar([ hw(0), 0], [ hw(tw_h), tw_h], 2.8);
    }
    translate([-tw_b - 0.6, 0]) square([2 * tw_b + 1.2, 1.1]);              // base plate
    translate([-TAB_W / 2, -3.5]) square([TAB_W, 3.51]);                    // tab for the foot slot
}
module braces2d() above_base() {                                             // Warren (zigzag) bracing
    for (k = [1 : bays - 1]) bar([-hw(k * bay), k * bay], [hw(k * bay), k * bay], 1.5);
    for (k = [0 : bays - 1]) {
        y0 = k * bay;  y1 = y0 + bay;
        if (k % 2 == 0) bar([-hw(y0), y0], [hw(y1), y1], 1.6);
        else            bar([ hw(y0), y0], [-hw(y1), y1], 1.6);
    }
}
module platform2d(y, ext) {                                                  // deck with a railing
    bar([-hw(y) - ext, y], [hw(y) + ext, y], 1.2);
    bar([-hw(y) - ext, y + 2.2], [hw(y) + ext, y + 2.2], 0.8);
    for (s = [-1, 1]) bar([s * (hw(y) + ext), y], [s * (hw(y) + ext), y + 2.2], 0.8);
}
module mast2d() {                                                            // antenna pipe above the lattice
    bar([0, tw_h - 1], [0, tw_h + 9], 2.2);
    translate([-1.8, tw_h + 8.2]) square([3.6, 3.2]);                        // beacon housing (whip hole)
    translate([0, tw_h + 11.4]) scale([1, 0.7]) circle(r = 1.8, $fn = 30);   // beacon dome
}
module arms2d() for (y = [tw_h + 1.6, tw_h + 6.6]) bar([-5.6, y], [5.6, y], 1.0);
module panels2d() for (s = [-1, 1]) translate([s * 5.2 - 0.85, tw_h + 0.6]) offset(r = 0.3) offset(delta = -0.3) square([1.7, 7.6]);

// ---------- microwave dishes (side view: drum with a domed radome) ----------
module dish2d(y, side, r) {        // side = +1 faces right, -1 faces left; r = dish half-height
    x0 = side * (hw(y) + 1.0);
    mirror([side < 0 ? 1 : 0, 0]) translate([abs(x0), 0]) {
        translate([0, y - r]) square([r * 0.9, 2 * r]);                     // drum body
        translate([r * 0.9, y]) scale([0.32, 1]) circle(r = r, $fn = 40);  // radome
    }
}
module dish_mount2d(y, side, r) bar([side * hw(y), y], [side * (hw(y) + 1.4), y], 1.4);
module radome2d(y, side, r) {
    x0 = side * (hw(y) + 1.0);
    mirror([side < 0 ? 1 : 0, 0]) translate([abs(x0) + r * 0.9, y]) scale([0.32, 1]) circle(r = r, $fn = 40);
}
D1 = [0.75 * tw_h, 1, 4.2];      // y, side, half-height
D2 = [0.42 * tw_h, -1, 3.2];

// ---------- aviation lights ----------
module lights2d() for (s = [-1, 1]) translate([s * (hw(tw_h / 2) + 1.0), tw_h / 2]) circle(r = 0.95, $fn = 20);

// ---------- band lines (red/white) ----------
nb = 7;  band = tw_h / nb;

module tower_part() {
    difference() {
        union() {
            linear_extrude(H_LEG) legs2d();
            linear_extrude(H_BRACE) braces2d();
            linear_extrude(H_DECK) { platform2d(0.62 * tw_h, 2.6); platform2d(tw_h - 0.6, 3.0); }
            linear_extrude(H_LEG) { mast2d(); arms2d(); }
            linear_extrude(H_PANEL) panels2d();
            linear_extrude(H_DECK) { dish_mount2d(D1[0], D1[1], D1[2]); dish_mount2d(D2[0], D2[1], D2[2]); lights2d(); }
            linear_extrude(H_DISH) { dish2d(D1[0], D1[1], D1[2]); dish2d(D2[0], D2[1], D2[2]); }
            linear_extrude(H_RADOME) { radome2d(D1[0], D1[1], D1[2]); radome2d(D2[0], D2[1], D2[2]); }
        }
        translate([0, 0, H_BRACE + 0.3]) linear_extrude(2) intersection() {                        // band lines, legs only
            difference() { legs2d(); dish2d(D1[0], D1[1], D1[2]); dish2d(D2[0], D2[1], D2[2]); lights2d(); }
            for (i = [1 : nb - 1]) translate([-12, i * band - 0.15]) square([24, 0.3]);
        }
        translate([0, tw_h + 11.6, H_LEG / 2]) rotate([90, 0, 0]) cylinder(d = 1.9, h = 6, $fn = 16);      // whip hole
    }
}

module tower_foot() difference() { cube([13.6, 6, 4.5]); translate([0.4, 1.3, 1]) cube([12.8, 3.4, 4]); }
module ape_foot() tower_foot();            // name kept for older preview files

part = "tower";
if (part == "tower") tower_part();
else if (part == "foot") tower_foot();
else if (part == "flat2d") {
    color("white") { legs2d(); braces2d(); }
    for (i = [0 : 2 : nb - 1]) color("firebrick") translate([0, 0, 0.05])
        intersection() { union() { legs2d(); braces2d(); } translate([-12, i * band]) square([24, band]); }
    color("gainsboro") translate([0, 0, 0.1]) { platform2d(0.62 * tw_h, 2.6); platform2d(tw_h - 0.6, 3.0); mast2d(); arms2d(); }
    color("lightgray") translate([0, 0, 0.15]) { panels2d(); dish_mount2d(D1[0], D1[1], D1[2]); dish_mount2d(D2[0], D2[1], D2[2]); }
    color("white") translate([0, 0, 0.2]) { dish2d(D1[0], D1[1], D1[2]); dish2d(D2[0], D2[1], D2[2]); }
    color("silver") translate([0, 0, 0.25]) { radome2d(D1[0], D1[1], D1[2]); radome2d(D2[0], D2[1], D2[2]); }
    color("red") translate([0, 0, 0.3]) { lights2d(); translate([0, tw_h + 11.4]) scale([1, 0.7]) circle(r = 1.8, $fn = 30); }
}
