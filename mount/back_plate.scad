// Back plate for the radar station. 39 x 39 mm, 2 mm thick. Covers the open back of the hut and
// rises 8.7 mm above the roof to brace the glue-on radio tower.
//
//   part = "plate"     : print orientation, outer face on the bed, no supports.
//   part = "installed" : in station coordinates (same frame as radar_station_adhesive.scad).
//
// Installed position (station coordinates): x 0.05..39.05, z 8.2..47.2 (bottom clears the fence
// rails by 0.2 mm), inner face against the hut's back face at y = 12.0.
// Inner face details:
//   - 0.3 mm relief behind the tower foot (its back is flush with the hut) so it can't hold the plate off
//   - 1.4 mm pad above the foot that reaches to 0.1 mm behind the tower's flat back: glue the tower to it

plate_w = 39;  plate_h = 39;  plate_t = 2;
x0 = 0.05;  z0 = 8.2;  y_in = 12.0;            // installed position
foot  = [16.3, 29.9, 38.5, 43.0];               // tower foot x0, x1, z0, z1
tower_back_y = 10.5;
pad   = [10.0, 36.2, 43.2, z0 + plate_h - 0.4]; // x0, x1, z0, z1 of the glue pad

module plate_installed() {
    difference() {
        union() {
            translate([x0, y_in, z0]) cube([plate_w, plate_t, plate_h]);
            translate([pad[0], tower_back_y + 0.1, pad[2]])
                cube([pad[1] - pad[0], y_in - tower_back_y - 0.1 + 0.01, pad[3] - pad[2]]);
        }
        translate([foot[0] - 0.2, y_in - 0.01, foot[2] - 0.2])
            cube([foot[1] - foot[0] + 0.4, 0.31, foot[3] - foot[2] + 0.4]);
    }
}

part = "plate";
if (part == "installed") plate_installed();
else if (part == "plate")   // outer face down: X = x, Y = z, Z = 14 - y
    translate([-x0, -z0, 0]) multmatrix([[1,0,0,0],[0,0,1,0],[0,-1,0,y_in + plate_t],[0,0,0,1]]) plate_installed();
