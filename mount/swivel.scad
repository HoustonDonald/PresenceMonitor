// Snap-together swivel between the monitor clip and the radar station. No hardware.
//
//   part = "base" : glue this disc to the clip's top bar. Print as-is (flat disc on the bed, post up).
//   part = "top"  : glue the station's base to this disc. Exported flipped (glue face on the bed).
//   part = "assembled" : both parts in their installed position, for checking.
//
// Assembly: push the top disc down over the post until the barb clicks into its seat, THEN glue.
// Keep glue away from the center of the top disc; the barb sits in a recess there.
// The barb is set `preload` mm low so the split fingers stay sprung against the 45 deg seat,
// which is what gives the swivel its friction. Too loose: raise preload. Too stiff: lower it.

part = "base";

D       = 28;     // disc diameter = the station's base depth (base_d), so it never shows past the station
base_t  = 3;      // base disc thickness
ring_h  = 0.6;    // raised bearing ring at the rim of the base disc (only the rim touches, no rocking)
ring_w  = 3;
top_t   = 6;      // top disc thickness
post_d  = 8;      // axle diameter
post_id = 5.2;    // axle bore (wall 1.4 mm so the fingers flex instead of crack)
hole_c  = 0.15;   // radial clearance between axle and top-disc hole
barb_d  = 9.2;    // barb diameter (0.45 mm catch per side over the hole)
slot_w  = 1.6;    // width of the two slots that split the post into 4 fingers
preload = 0.2;    // how far below its seat the barb is drawn (sets friction)

hole_d  = post_d + 2*hole_c;
z_top0  = base_t + ring_h;            // underside of the top disc when assembled
seat_lo = 2.5;                        // depth (from the top disc's underside) where the 45 deg seat starts
z_seat_hole = z_top0 + seat_lo;
z_barb  = z_seat_hole - hole_c - preload;   // where the barb's 45 deg underside starts on the post
barb_flare = (barb_d - post_d) / 2;
barb_top   = z_barb + barb_flare + 0.4 + 1.2;
cb_d    = barb_d + 1.2;               // recess above the seat that houses the barb head

$fn = 96;

module base_part() {
    difference() {
        union() {
            cylinder(d = D, h = base_t);
            translate([0, 0, base_t - 0.01]) difference() {
                cylinder(d = D, h = ring_h + 0.01);
                translate([0, 0, -1]) cylinder(d = D - 2*ring_w, h = ring_h + 2);
            }
            // axle + barb
            cylinder(d = post_d, h = z_barb + 0.01);
            translate([0, 0, z_barb]) cylinder(d1 = post_d, d2 = barb_d, h = barb_flare);   // 45 deg underside
            translate([0, 0, z_barb + barb_flare - 0.01]) cylinder(d = barb_d, h = 0.41);
            translate([0, 0, z_barb + barb_flare + 0.4]) cylinder(d1 = barb_d, d2 = post_d - 1, h = 1.2); // lead-in
        }
        // bore and a groove around the post's root so the fingers are long enough to flex
        translate([0, 0, 1.2]) cylinder(d = post_id, h = 50);
        translate([0, 0, 1.2]) difference() {
            cylinder(d = post_d + 2.4, h = base_t - 1.2 + 0.01);
            translate([0, 0, -1]) cylinder(d = post_d - 0.01, h = 12);
        }
        // cross slots -> 4 fingers
        for (a = [0, 90]) rotate([0, 0, a]) translate([-slot_w/2, -10, 1.2]) cube([slot_w, 20, 50]);
    }
}

module top_part() {
    difference() {
        cylinder(d = D, h = top_t);
        translate([0, 0, -1]) cylinder(d = hole_d, h = top_t + 2);
        // 45 deg seat for the barb, then the recess that hides the barb head
        translate([0, 0, seat_lo]) cylinder(d1 = hole_d, d2 = cb_d - 0.1, h = (cb_d - 0.1 - hole_d)/2 + 0.001);
        translate([0, 0, seat_lo + (cb_d - 0.1 - hole_d)/2]) cylinder(d = cb_d, h = top_t);
        // small chamfer on the underside entry helps the barb start
        translate([0, 0, -0.01]) cylinder(d1 = hole_d + 1.2, d2 = hole_d, h = 0.6);
    }
}

if (part == "base") base_part();
else if (part == "top") translate([0, 0, top_t]) rotate([180, 0, 0]) top_part();
else if (part == "assembled") { base_part(); translate([0, 0, z_top0]) top_part(); }
else if (part == "section") difference() {
    union() { color("orange") base_part(); color("steelblue") translate([0, 0, z_top0]) top_part(); }
    translate([-50, 0, -1]) cube([100, 50, 50]);
}

echo(str("stack height = ", z_top0 + top_t, " mm; barb top z = ", barb_top, "; top surface z = ", z_top0 + top_t));
