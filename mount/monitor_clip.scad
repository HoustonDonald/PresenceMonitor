// Monitor clip for the radar station, OBSBOT-style: a top bar that hooks the monitor's front
// edge and a hinged back leg that swings down against the back of the monitor.
// Hardware: 1x M3 x 40 socket head cap screw + 1x M3 hex nut (nut sits in a hex pocket).
// Tighten the screw until the leg holds its angle.
//
//   part = "top" : top bar. Print with its TOP face down on the bed (exported that way).
//   part = "leg" : back leg. Print with its monitor-side face down on the bed (exported that way).
//   part = "preview" : assembled with the station on top (for looking only).
//
// The station's adhesive base glues (or VHB-tapes) onto the top bar, front edges flush.
// Assembly coordinates: X across, Y front-to-back (0 = monitor front face), Z up (0 = where the
// top bar's underside sits on the monitor's front edge).

/* ---------- set these ---------- */
front_lip = 8;      // how far the front lip hangs down over the bezel (keep it off the screen)
leg_len   = 55;     // hinge axis to the end of the leg
hinge_y   = 36;     // hinge axis distance behind the monitor front; keeps the knuckles behind a ~30 mm top
leg_angle = 10;     // preview only: leg swing out from straight down

/* ---------- usually leave ---------- */
W   = 39.1;         // width, matches the station
t   = 4;            // top bar thickness
R   = 4.5;          // knuckle radius
za  = -0.4;         // hinge axis height (knuckle top is cut flush with the bar's top face)
clr = 0.4;          // gap between knuckles
k1  = 10;  k2 = W - 10;          // bar knuckles [0, k1] and [k2, W]; leg knuckle between
pin_bar = 3.3;  pin_leg = 3.4;   // M3 clearance holes
nut_af = 5.5;  nut_depth = 2.6;  // M3 nut across flats, pocket depth
leg_t = 4;

module xcyl(x0, x1, r, fn = 48) translate([x0, hinge_y, za]) rotate([0, 90, 0]) cylinder(r = r, h = x1 - x0, $fn = fn);

module top_bar() {
    difference() {
        union() {
            translate([0, -4, 0]) cube([W, hinge_y + 4, t]);                    // bar
            translate([0, -4, -front_lip]) cube([W, 4, front_lip + 0.01]);      // front lip
            for (xr = [[0, k1], [k2, W]]) intersection() {                     // bar knuckles: flush on top, with a
                hull() {                                                       // 45-degree lead-in behind them so the
                    xcyl(xr[0], xr[1], R);                                     // part never starts over air when the
                    translate([xr[0], hinge_y, t - 0.01]) cube([xr[1] - xr[0], R + 0.9, 0.01]);   // top face is on the bed
                }
                translate([-1, 0, -20]) cube([W + 2, 100, 20 + t]);
            }
        }
        xcyl(k1, k2, R + 0.6);                                                 // room for the leg knuckle to turn
        translate([k1, hinge_y - R - 0.6, -10]) cube([k2 - k1, 2 * R + 2, 10]);
        xcyl(-1, W + 1, pin_bar / 2, 24);                                       // screw hole
        // captured nut pocket on the right end, a vertex pointing down the print (no flat ceiling)
        translate([W - nut_depth, hinge_y, za]) rotate([0, 90, 0])
            cylinder(d = nut_af / cos(30) + 0.35, h = nut_depth + 1, $fn = 6);
    }
}

// leg in its own frame: hinge axis on the X axis through the origin, hanging down -Z.
// Flat face toward the monitor at y = -LF (that face goes on the bed); the barrel is trimmed
// 1 mm there so it has a flat to stand on.
LF = R - 1.0;
module leg_local() {
    lx0 = k1 + clr;  lx1 = k2 - clr;
    difference() {
        intersection() {
            union() {
                translate([lx0, 0, 0]) rotate([0, 90, 0]) cylinder(r = R, h = lx1 - lx0, $fn = 48);
                translate([lx0, -LF, -leg_len]) cube([lx1 - lx0, leg_t, leg_len]);
                translate([lx0, -LF, -leg_len]) cube([lx1 - lx0, leg_t + 2, 10]);     // stiffer foot
            }
            translate([lx0 - 1, -LF, -leg_len - 1]) cube([lx1 - lx0 + 2, 20, leg_len + 10]);
        }
        translate([lx0 - 1, 0, 0]) rotate([0, 90, 0]) cylinder(d = pin_leg, h = lx1 - lx0 + 2, $fn = 24);
    }
}
module leg_installed() translate([0, hinge_y, za]) rotate([leg_angle, 0, 0]) leg_local();

part = "top";
if (part == "top") translate([0, 0, t]) rotate([180, 0, 0]) top_bar();          // top face on the bed
else if (part == "leg") translate([0, 0, LF]) rotate([90, 0, 0]) leg_local();   // monitor-side face on the bed
else if (part == "top_installed") top_bar();
else if (part == "leg_installed") leg_installed();
else if (part == "preview") { top_bar(); leg_installed(); }
