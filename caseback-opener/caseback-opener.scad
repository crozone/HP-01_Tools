// Caseback Opener Tool for Hewlett Packard HP-01 LED Watch
// Ryan Crosby 2023

// Use knurling library
use <../libs/knurledFinishLib_v2.scad>
use <../libs/text_on.scad>
use <../libs/shared.scad>

// Config
$fn= $preview ? 32 : 256;


// Mode 0: Export with no text
// Mode 1: Export with embossed text, for filling with filler paint later
// Mode 2: Export text only. For use in conjunction with Mode 1 for multi-material printing in the slicer.
TEXT_MODE = 0;

// Constants
BACK_OUTER_D = 35.8;
BACK_INNER_D = 28;

PART_OUTER_D = BACK_OUTER_D;

HANDLE_HEIGHT = 10;
HANDLE_BASE_HEIGHT = 3;

TEXT_ENGRAVE_HEIGHT = 0.20; // Make this the first layer height

RADIAL_SLOT_KEEPOUT_DIAMETER = 20.5;
RADIAL_SLOT_WIDTH = 1.3 - 0.1; // Measured to be 1.3mm, 0.1mm tolerence
RADIAL_SLOT_LENGTH = PART_OUTER_D / 2 - RADIAL_SLOT_KEEPOUT_DIAMETER / 2;
RADIAL_SLOT_DEPTH = 0.5 + 0.1; // Measured to be 0.5mm, add 0.1mm to raise height slighly
RADIAL_SLOT_INNER_LENGTH = 2.5 - 0.1; // Measured to be 2.5mm, 0.1mm tolerence
RADIAL_SLOT_INNER_DEPTH = RADIAL_SLOT_DEPTH + 0.3 - 0.1; // Measured to be 0.9, 0.3 higher than the slot depth.

module radial_slot_gripper_2d() {
    union() {
        translate([RADIAL_SLOT_WIDTH / 2, 0])
        circle(d = RADIAL_SLOT_WIDTH);

        translate([RADIAL_SLOT_WIDTH / 2, -RADIAL_SLOT_WIDTH / 2])
        square([RADIAL_SLOT_LENGTH - (RADIAL_SLOT_WIDTH / 2), RADIAL_SLOT_WIDTH]);
    }
}

module radial_slot_gripper_inner_2d() {
        translate([RADIAL_SLOT_WIDTH / 2, 0])
    hull() {
        circle(d = RADIAL_SLOT_WIDTH);

        translate([RADIAL_SLOT_INNER_LENGTH - RADIAL_SLOT_WIDTH, 0])
        circle(d = RADIAL_SLOT_WIDTH);
    }
}

module chamfer_point_2d(dim) {
    x_off = 0.4;

    union() {
        p1 = concat([
            [-dim[0]/2, 0],
            [-dim[0]/2, dim[1]],
            [-x_off/2, dim[1]],
        ]);

        polygon(p1);

        p2 = concat([
            [dim[0]/2, 0],
            [x_off/2, dim[1]],
            [dim[0]/2, dim[1]],
        ]);

        polygon(p2);
    }
}

module radial_slot_grippers() {
    difference() {
        union() {
            color("green")
            linear_extrude(height = RADIAL_SLOT_DEPTH, center = false)
            intersection() {
                union() {
                    for ( i = [0 : 1 : 6] )
                    {
                        rotate(i * 60)
                        translate([RADIAL_SLOT_KEEPOUT_DIAMETER / 2, 0])
                        radial_slot_gripper_2d();
                    }
                }
                circle(d = PART_OUTER_D);
            }

            color("blue")
            linear_extrude(height = RADIAL_SLOT_INNER_DEPTH, center = false)
            union() {
                for ( i = [0 : 1 : 6] )
                {
                    rotate(i * 60)
                    translate([RADIAL_SLOT_KEEPOUT_DIAMETER / 2, 0])
                    radial_slot_gripper_inner_2d();
                }
            }
        }

        chamfer_height = 0.4;
        for ( i = [0 : 1 : 6] )
        {
            rotate(i * 60)
            translate([RADIAL_SLOT_KEEPOUT_DIAMETER / 2, 0, RADIAL_SLOT_INNER_DEPTH - chamfer_height + 0.01])
            rotate([90, 0, 90])
            linear_extrude(height = RADIAL_SLOT_LENGTH)
            chamfer_point_2d([RADIAL_SLOT_WIDTH + 0.01, chamfer_height]);
        }
    }
}

module main_base() {
    union() {
        translate([0, 0, -HANDLE_BASE_HEIGHT])
        cylinder(d = PART_OUTER_D, h = HANDLE_BASE_HEIGHT);

        // Do not render knurling during preview.
        // It is extremely slow to render.
        if($preview) {
            translate([0, 0, -HANDLE_HEIGHT])
            cylinder(d = PART_OUTER_D, h = HANDLE_HEIGHT - HANDLE_BASE_HEIGHT);
        }
        else {
            // Knurling
            translate([0, 0, -HANDLE_HEIGHT])
            intersection() {
                knurl(k_cyl_hg = (HANDLE_HEIGHT - HANDLE_BASE_HEIGHT) * 2, k_cyl_od = PART_OUTER_D - 0.5, s_smooth=50, e_smooth = 2);
                cylinder(h = (HANDLE_HEIGHT - HANDLE_BASE_HEIGHT), d = PART_OUTER_D);
            }
        }

        radial_slot_grippers();
    }
}

module top_embossing() {
    rotate([180, 0, 0]) {
        font = "Liberation Mono:style=Bold";//"Cascadia Mono";
        size = 4;
        spacing=1.1;
        radius = BACK_OUTER_D / 2 - 4.2;

        text_on_circle("TIGHT",
        r = radius,
        rotate=90,
        extrusion_height=TEXT_ENGRAVE_HEIGHT * 2,
        font=font,
        size=size,
        spacing=spacing
        );

        text_on_circle("LOOSE",
        r = radius,
        rotate=270,
        extrusion_height=TEXT_ENGRAVE_HEIGHT * 2,
        font=font,
        size=size,
        spacing=spacing
        );

        translate([0, 0, -TEXT_ENGRAVE_HEIGHT])
        linear_extrude(height = TEXT_ENGRAVE_HEIGHT * 2) {
            rotate(270 + 20)
            difference() {
                round_arrow_2d(radius, 130, 1, 3);
                rotate(30)
                arc_intersector_2d(r = radius, a = 80);
            }

            rotate(270 - 20)
            scale([1, -1])
            difference() {
                round_arrow_2d(radius, 130, 1, 3);
                rotate(30)
                arc_intersector_2d(r = radius, a = 80);
            }
        }
    }
}

module total_part() {
    difference() {
        union() {
            main_base();

            // Add grip nubs
            translate([0, 0, -HANDLE_HEIGHT])
            union() {
                translate([0, PART_OUTER_D / 2, 0])
                cylinder(r = 4, h = HANDLE_HEIGHT - HANDLE_BASE_HEIGHT);

                translate([0, -PART_OUTER_D / 2, 0])
                cylinder(r = 4, h = HANDLE_HEIGHT - HANDLE_BASE_HEIGHT);
            }
        }

        // Small holes in the top for gripping with standard watch caseback openers
        translate([0, 0, -HANDLE_HEIGHT - 0.1])
        union() {
            translate([0, 13, 0])
            cylinder(d = 3, h = 3 + 0.1);

            translate([0, -13, 0])
            cylinder(d = 3, h = 3 + 0.1);
        }

        // Center hole
        #translate([0, 0, -HANDLE_HEIGHT - 0.5])
        cylinder(h = HANDLE_HEIGHT + 1, d = RADIAL_SLOT_KEEPOUT_DIAMETER);

        // Text embossing
        if(TEXT_MODE == 1) {
            translate([0, 0, -HANDLE_HEIGHT])
            top_embossing();
        }
    }

    // Guide for inner slots
    %cylinder(h = 2, d = RADIAL_SLOT_KEEPOUT_DIAMETER);
}

// Text embossing inverse
if(TEXT_MODE == 2) {
    translate([0, 0, -HANDLE_HEIGHT])
    difference() {
        top_embossing();

        translate([0, 0, -10])
        cylinder(h = 10, r = PART_OUTER_D / 2);
    }
}
else {
    total_part();
}