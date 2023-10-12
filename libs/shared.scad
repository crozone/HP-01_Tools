// Shared functions
// Ryan Crosby 2023

// Generates a 2D polygon that, when intersected with a circle, creates an arc in that circle.
// r = radius of circle
// a = angle of arc
module arc_intersector_2d(r, a) {
    // This function chains together triangles to effectively create an arc
    // which is guaranteed to cover the outside of a circle with the given radius.

    // Three points are the minimum required,
    // but 4 makes the shape nice and right angled.
    // This can be set higher (eg to $fn), but there's
    // no functional purpose in doing so.
    fn = 4;

    // Calculate the radius required to completely cover the circle.
    // Add some small buffer for rounding errors
    arc_rad = r / cos(180 / fn) + 0.5;
    step = 360 / fn;

    // calculate the points for polygon
    points = concat([[0, 0]],
        [for(theta = [0 : step : a]) 
            [arc_rad * cos(theta), arc_rad * sin(theta)]
        ],
        [[arc_rad * cos(a), arc_rad * sin(a)]]
    );

    polygon(points);
}

module round_arrow_2d(r, a, line_width = 1, point_length = 4) {
    angle_offset = atan((sqrt(2*line_width))/r);
    line_angle = a - angle_offset;

    rotate(angle_offset)
    union() {
        intersection() {
            difference() {
                circle(r=r+line_width/2);
                circle(r=r-line_width/2);
            }

            arc_intersector_2d(r, line_angle);
        }

        translate([r, -sqrt(2*line_width)])
        rotate(45)
        difference() {
            square([point_length, point_length]);

            translate([line_width, line_width])
            square([point_length - line_width + 0.1, point_length - line_width + 0.1]);
        }
    }
}