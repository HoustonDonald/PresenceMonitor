// Presence Monitor - radar station, adhesive-base version (no clip)
// LOLIN S2 Mini + HLK-LD2410C stack in a hut on a flat base that sticks to the monitor top
// with a Command strip or 3M VHB. Dish faceplate glued on the front.
// All dimensions in mm. Edit the values, F6 to render, F7 to export.
//
// Three printed parts, no supports (only short bridges of 5 mm or less):
//   part = "station" : base + riser + hut. Print FRONT FACE DOWN (radar wall on the bed, open
//                      back facing up). Exported already in that position.
//   part = "dish"    : dish faceplate. Print flat back down. 0.12 mm layers look best.
//   part = "tower"   : lattice comms tower. Print standing up as exported; glue into the roof socket.
//   part = "preview" : both, assembled (for looking only).
//
// Coordinates (assembled): X = across the monitor, Y = front-to-back (0 = monitor front edge,
// +Y = back), Z = up (0 = top surface of the monitor). USB-C slot on the right, seen from the front.

/* ---------- Measure / set these ---------- */
base_d    = 28;    // base depth front-to-back; keep it under the monitor's ~30 mm top depth
stack_t   = 10;    // board stack thickness incl. USB-C connector and solder points (measured 10 mm)

/* ---------- Radar window (where the radar antennas sit, seen from the front) ---------- */
win_dx    = 3.3;   // window center offset from hut-face center, + = toward USB side (estimate)
win_dz    = 6.6;   // window center offset from hut-face center, + = up (estimate)
win_d     = 30;    // window hole diameter in the dish
win_cover = false; // true = 0.8 mm skin over the window (untested for radar range)

/* ---------- Detail (all print without supports, front face down) ---------- */
siding    = true;  // corrugated siding grooves on the side walls and roof
door      = true;  // recessed door with handle on the left wall
roof_kit  = true;  // roof parapet and a rooftop HVAC unit at the front edge
mast      = false; // flat mast molded on the front-left corner (off: use the glue-on tower instead)
tower     = true;  // socket on the roof for the separate glue-on lattice tower (part = "tower")
tower_h   = 24.6;   // lattice tower height
fence     = true;  // perimeter fence on the base behind the hut

/* ---------- Dish ---------- */
dish_d    = 56;  dish_bowl = 4.5;  dish_fn = 120;

/* ---------- Usually leave these ---------- */
pcb_len = 34.3;  pcb_h = 25.4;  radar_over = 2.0;  clr = 0.4;
base_t = 3;  wall = 2.0;  front_w = 1.2;
usb_slot_h = 14;  btn_len = 7;

/* ---------- Derived ---------- */
in_x = pcb_len + 2*clr;   in_y = stack_t + 2*clr;   in_z = pcb_h + radar_over + 2*clr;
box_x = in_x + 2*wall;    box_y = front_w + in_y;   box_z = wall + in_z + wall;
R = dish_d / 2;
ped_h = max(0, R - box_z/2 - win_dz - base_t + 1);   // riser so the dish clears the screen by 1 mm
zb = base_t + ped_h;                                  // hut floor
face_c = [box_x/2, 0, zb + box_z/2];                  // hut front-face center

function zf(r) = 1.8 + dish_bowl * pow(r / R, 2);

zt = zb + box_z;                                      // roof surface

module diamond_holes_yz(x0, w, y0, y1, z0, z1, d) {   // diamond holes through a plate in the YZ plane
    a = d / sqrt(2);
    for (z = [z0 + d/2 + 1 : d + 1 : z1 - d/2 - 1])
        translate([x0 - 1, (y0 + y1)/2, z]) rotate([45, 0, 0]) cube([w + 2, a, a], center = true);
}

module details_add() {
    if (roof_kit) {
        // parapet: front and side rims (start at the front face, so they grow from the bed)
        translate([0, 0, zt - 0.01]) cube([box_x, 1.0, 1.6]);
        translate([0, 0, zt - 0.01]) cube([1.0, box_y, 1.6]);
        translate([box_x - 1.0, 0, zt - 0.01]) cube([1.0, box_y, 1.6]);
        // rooftop HVAC unit, flush with the front edge
        translate([5, 0, zt - 0.01]) cube([11, 7, 4.5]);
    }
    if (mast) {
        // flat lattice mast at the front-left corner (a short wall when printing)
        difference() {
            translate([0, 0, zt - 0.01]) cube([1.6, 4, 17]);
            diamond_holes_yz(0, 1.6, 0, 4, zt + 1, zt + 15, 2.2);
        }
        translate([-0.6, 0, zt + 17 - 0.01]) cube([2.8, 3, 2.2]);    // beacon housing
    }
    if (door) translate([-0.6, 4.6, zb + 9.5]) cube([0.61, 1.2, 1.8]); // door handle (0.6 mm, tiny ledge)
    if (fence && base_d > box_y + 3) {
        fy0 = box_y;  fy1 = base_d;  fz0 = base_t - 0.01;  fh = 5;
        for (x = [0, box_x - 1]) {                                 // side rails, continuing back from the hut walls
            translate([x, fy0 - 0.01, fz0 + fh - 1]) cube([1, fy1 - fy0, 1]);
            for (y = [fy0 : 4 : fy1 - 1]) translate([x, y, fz0]) cube([1, 1, fh]);
        }
        translate([0, fy1 - 1, fz0]) cube([1, 1, fh]);
        translate([box_x - 1, fy1 - 1, fz0]) cube([1, 1, fh]);
        translate([0, fy1 - 1, fz0 + fh - 1]) cube([box_x, 1, 1]);     // back rail (short bridges between posts)
        for (x = [5 : 5 : box_x - 5]) translate([x, fy1 - 1, fz0]) cube([1, 1, fh]);
    }
}

module details_cut() {
    if (siding) {
        // vertical corrugation grooves on both side walls
        for (x = [-0.01, box_x - 0.5]) for (y = [2 : 2.4 : box_y - 1])
            translate([x, y, zb + 1]) cube([0.51, 0.8, box_z - 2]);
        // roof corrugation, front-to-back grooves (clear of the rooftop unit and parapet)
        for (x = [17.5 : 2.4 : box_x - 2.5]) translate([x, 1.2, zt - 0.5]) cube([0.8, box_y, 0.51]);
    }
    if (door) {
        translate([-0.01, 3, zb + 1.5]) cube([0.71, 6.5, box_z * 0.68]);          // door recess
        translate([-0.01, 3.6, zb + 2.2 + box_z * 0.68 - 4.5]) cube([0.9, 5.3, 2.4]); // door window
    }
    if (tower) translate([1.6, box_y - 7.4, zt - 0.6]) cube([6.4, 6.4, 0.61]);   // tower socket (back-left)
    if (roof_kit) {
        // grille slots in the top of the HVAC unit and a louvre panel on its front
        for (x = [6.5 : 1.6 : 15]) translate([x, 1.2, zt + 3.9]) cube([0.7, 4.6, 0.7]);
    }
}

module station() {
    difference() {
        union() {
            cube([box_x, base_d, base_t]);                                   // base (adhesive goes under it)
            translate([0, 0, base_t - 0.01]) cube([box_x, box_y, ped_h + 0.02]);   // solid riser
            translate([0, 0, zb]) cube([box_x, box_y, box_z]);               // hut
            details_add();
        }
        details_cut();
        // board cavity, open at the back (top of the print)
        translate([wall, front_w, zb + wall]) cube([in_x, in_y + 1, in_z]);
        // USB-C slot, right side, open to the back
        translate([box_x - wall - 1, front_w, zb + wall + clr + pcb_h/2 - usb_slot_h/2])
            cube([wall + 2, in_y + 1, usb_slot_h]);
        // button slot in the top wall at the USB end, open to the back
        translate([box_x - wall - btn_len, front_w, zb + wall + in_z - 1])
            cube([btn_len, in_y + 1, wall + 4]);
    }
}


// simple square tower, printed upright: 1.6 mm corner posts and 1.2 mm rings every 5 mm
// (no diagonals, rings bridge 2.8 mm), platform and beacon on top with a 2 mm hole for a
// short piece of 1.75 mm filament as the whip antenna. 6 mm foot fits the roof socket.
module lattice_tower() {
    w = 6;  p = 1.6;  seg = 5;  h = tower_h;
    translate([0, 0, 0]) difference() {
        union() {
            cube([w, w, 0.8]);                                                     // foot
            for (x = [0, w - p], y = [0, w - p]) translate([x, y, 0]) cube([p, p, h]);   // corner posts
            for (z = [seg : seg : h - 1]) difference() {                           // rings
                translate([0, 0, z]) cube([w, w, 1.2]);
                translate([p, p, z - 1]) cube([w - 2*p, w - 2*p, 3.2]);
            }
            translate([-0.2, -0.2, h - 0.01]) cube([w + 0.4, w + 0.4, 1.2]);      // platform
            translate([w/2, w/2, h + 1.19]) cylinder(d1 = 4, d2 = 3, h = 3, $fn = 24);   // beacon
        }
        translate([w/2, w/2, h - 1.5]) cylinder(d = 2.0, h = 10, $fn = 16);       // whip hole, 5.7 mm deep
    }
}

module dish() {
    rw = win_d / 2;  N = 40;  edge = 0.8;
    Rb = R - (zf(R) - edge);                       // 45-degree skirt on the back
    union() {
        rotate_extrude($fn = dish_fn)
            polygon(concat([[rw, 0], [Rb, 0], [R, zf(R) - edge]],
                           [for (i = [0 : N]) let(r = R - (R - rw) * i / N) [r, zf(r)]]));
        rotate_extrude($fn = dish_fn)
            polygon([[R - 1.6, zf(R) - edge], [R, zf(R) - edge], [R, zf(R) + 1.2], [R - 1.6, zf(R - 1.6) + 1.2]]);
        rotate_extrude($fn = dish_fn)
            polygon([[rw, 0], [rw + 1.6, 0], [rw + 1.6, zf(rw) + 2.5], [rw, zf(rw) + 2.5]]);
        for (a = [45 : 90 : 359]) rotate([0, 0, a]) rotate([90, 0, 0])
            linear_extrude(1.2, center = true)
                polygon(concat([for (i = [0 : 12]) let(r = rw + 1.5 + (R - 1.6 - rw - 1.5) * i / 12) [r, zf(r) - 0.5]],
                               [for (i = [12 : -1 : 0]) let(r = rw + 1.5 + (R - 1.6 - rw - 1.5) * i / 12) [r, zf(r) + 0.8]]));
        for (a = [0 : 30 : 359]) rotate([0, 0, a]) translate([R - 0.8, 0, zf(R) + 1.2 - 0.5])
            cylinder(d = 1.2, h = 1.1, $fn = 12);
        if (win_cover) cylinder(r = rw + 0.2, h = 0.8, $fn = dish_fn);
    }
}

module dish_placed() { translate(face_c + [win_dx, 0, win_dz]) rotate([90, 0, 0]) dish(); }

part = "station";
if (part == "station") rotate([90, 0, 0]) station();          // front face down on the bed
else if (part == "station_installed") station();
else if (part == "dish") dish();
else if (part == "tower") lattice_tower();
else if (part == "tower_placed") translate([1.6 + 0.2, box_y - 7.4 + 0.2, zt - 0.6]) lattice_tower();
else if (part == "dish_placed") dish_placed();
else if (part == "preview") { station(); color("silver") dish_placed();
                               if (tower) translate([1.6 + 0.2, box_y - 7.4 + 0.2, zt - 0.6]) lattice_tower(); }
