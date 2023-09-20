/* [Model] */
// The model to generate. Either "box", "lid" or "exploded".
model = "box"; // [box, lid, exploded]

/* [Cuts] */
// The number of cuts to make. Cuts are evenly spaced between start and end.
cut_units = 6;
// The cut to start at.
cut_start = 0;
// The cut to end at.
cut_end = 2;

/* [Box] */
// The length of the box.
box_length = 480;
// The width of the box.
box_width = 160;
// The rounding of box corners.
box_rounding = 20;
// The thickness of the box floor.
box_floor_thickness = 2;
// The height of the box walls.
box_wall_height = 120;
// The thickness of the box walls.
box_wall_thickness = 2;
// The height of the box slits.
box_slit_height = 100;
// The width of the box slits.
box_slit_width = 20;
// The rounding of the box slits.
box_slit_rounding = 10;

/* [Lid] */
// The thickness of the lid ceiling.
lid_ceil_thickness = 2;
// The clearance between the lid and the box.
lid_clearance = 0.0; // 0.05
// The height of the lid walls.
lid_wall_heigth = 20;
// The thickness of the lid walls.
lid_wall_thickness = 2;

/* [Connectors] */
// The width of the screw thread.
screw_thread_width = 3;
// The height of the screw thread.
screw_thread_height = 12;
// The oversize of the screw thread.
screw_thread_oversize = 0.1; // 0.05
// The width of the screw head.
screw_head_width = 5.5; // 0.1
// The height of the screw head.
screw_head_height = 3; // 0.1
// The oversize of the screw head.
screw_head_oversize = 0.1; // 0.05
// The width of the screw nut.
screw_nut_width = 5.5; // 0.1
// The height of the screw nut.
screw_nut_height = 2.4; // 0.1
// The oversize of the screw nut.
screw_nut_oversize = 0.1; // 0.05
// The connector width.
joiner_width = 8;

/* [Rendering] */
// The distance between the exploded box parts.
exploded_box_part_distance = 30;
// The distance between the exploded lid parts.
exploded_lid_part_distance = 20;
// The distance between the box and the lid in the exploded view.
exploded_box_lid_distance = 40;
// The number of fragments to use for rounded shapes.
$fn = 64;

// Check parameters.
assert(model == "box" || model == "lid" || model == "exploded");
assert(0 <= cut_start);
assert(cut_start < cut_end);
assert(cut_end <= cut_units);

// Derived parameters.
cut_start_ratio = cut_start / cut_units;
cut_end_ratio = cut_end / cut_units;
cut_y_min = box_length * (cut_start_ratio - 0.5);
cut_y_max = box_length * (cut_end_ratio - 0.5);

box_inner_width = box_width - 2 * box_wall_thickness;
box_inner_length = box_length - 2 * box_wall_thickness;
box_inner_rounding = box_rounding - box_wall_thickness;

lid_wall_rounding = box_inner_rounding - lid_clearance;
lid_wall_width = box_inner_width - 2 * lid_clearance;
lid_wall_length = box_inner_length - 2 * lid_clearance;
lid_slit_width = box_slit_width - 2 * lid_clearance;
lid_slit_rounding_top = box_slit_rounding + lid_clearance;
lid_slit_rounding_bot = box_slit_rounding - lid_clearance;
lid_slit_thickness = box_wall_thickness + lid_clearance + lid_wall_thickness;
lid_inner_width = lid_wall_width - 2 * lid_wall_thickness;

joiner_length = screw_head_height + screw_thread_height;
joiner_height = 2 * joiner_length;

// Model
// =====

if (model == "box")
    box(cut_start, cut_end, cut_units);
else if (model == "lid")
    lid(cut_start, cut_end, cut_units);
else if (model == "exploded")
    exploded_view();

// Box
// ===

module box(cut_start, cut_end, cut_units)
{
    assert(all_defined([ cut_start, cut_end, cut_units ]));
    split_model(cut_start, cut_end, cut_units)
    {
        box_monoblock();
        translate([ 0, 0, box_floor_thickness ]) box_joiners();
    }
}

module box_monoblock()
{
    box_floor();
    translate([ 0, 0, box_floor_thickness ]) box_wall();
}

module box_floor()
{
    linear_extrude(height = box_floor_thickness) rect(size = [ box_width, box_length ], rounding = box_rounding);
}

module box_wall()
{
    difference()
    {
        box_blind_wall();
        translate([ 0, 0, box_wall_height - box_slit_height / 2 ]) box_slit_mask_3d();
    }
}

module box_blind_wall()
{
    rect_tube(height = box_wall_height, size = [ box_width, box_length ], wall = box_wall_thickness,
              rounding = box_rounding);
}

module box_slit_mask_3d()
{
    rotate([ 90, 0, 0 ]) linear_extrude(height = box_length + 2, center = true) box_slit_mask_2d();
}

module box_slit_mask_2d()
{
    window_shape_2d(size = [ box_slit_width, box_slit_height ], ir = box_slit_rounding, or = box_slit_rounding);
    translate([ 0, box_slit_height / 2 + 0.5 ]) square([ box_slit_width + 2 * box_slit_rounding, 1 ], center = true);
}

module box_joiners()
{
    x_l = -box_inner_width / 2 + joiner_width / 2;
    x_r = -x_l;
    z_b = joiner_width / 2;
    z_t = box_wall_height - lid_wall_heigth - joiner_width / 2 - 1; // -1 for clearance.

    translate([ x_l, 0, z_b ]) mirror([ 0, 1, 0 ]) joiner();
    translate([ x_r, 0, z_b ]) rotate([ 0, 0, 180 ]) mirror([ 0, 1, 0 ]) joiner();
    translate([ x_l, 0, z_t ]) rotate([ 180, 0, 0 ]) joiner();
    translate([ x_r, 0, z_t ]) rotate([ 180, 0, 180 ]) joiner();
}

module window_shape_2d(size, ir, or)
{
    difference()
    {
        union()
        {
            rect(size = size, rounding = ir);
            translate([ 0, ir / 2 ]) rect(size = [ size.x, size.y - ir ]);
            translate([ 0, size.y / 2 - or / 2 ]) rect(size = [ size.x + 2 * or, or ]);
        }
        translate([ -size.x / 2 - or, size.y / 2 - or ]) circle(r = or);
        translate([ size.x / 2 + or, size.y / 2 - or ]) circle(r = or);
    }
}

// Lid
// ===

module lid(cut_start, cut_end, cut_units)
{
    assert(all_defined([ cut_start, cut_end, cut_units ]));
    split_model(cut_start, cut_end, cut_units)
    {
        lid_monoblock();
        translate([ 0, 0, lid_ceil_thickness ]) lid_joiners();
    }
}

module lid_monoblock()
{
    lid_ceil();
    translate([ 0, 0, lid_ceil_thickness ]) lid_wall();
}

module lid_ceil()
{
    linear_extrude(height = lid_ceil_thickness) rect(size = [ box_width, box_length ], rounding = box_rounding);
}

module lid_wall()
{
    lid_inner_wall();
    for (i = [ -1, 1 ])
        translate([ 0, i * (box_length / 2 - lid_slit_thickness / 2), lid_wall_heigth / 2 ]) lid_slit();
}

module lid_inner_wall()
{
    rect_tube(height = lid_wall_heigth, size = [ lid_wall_width, lid_wall_length ], wall = lid_wall_thickness,
              rounding = lid_wall_rounding);
}

module lid_slit()
{
    rotate([ 90, 0, 0 ]) linear_extrude(height = lid_slit_thickness, center = true) lid_slit_2d();
}

module lid_slit_2d()
{
    rotate([ 0, 0, 180 ]) intersection()
    {
        translate([ 0, lid_wall_heigth / 2 - box_slit_height / 2 ]) window_shape_2d(
            size = [ lid_slit_width, box_slit_height ], ir = lid_slit_rounding_bot, or = lid_slit_rounding_top);
        square([ 1000, lid_wall_heigth ], center = true);
    }
}

module lid_joiners()
{
    x_l = -lid_inner_width / 2 + joiner_width / 2;
    x_r = -x_l;
    z_b = joiner_width / 2;

    translate([ x_l, 0, z_b ]) rotate([ 180, -90, 0 ]) joiner();
    translate([ x_r, 0, z_b ]) rotate([ 0, -90, 0 ]) joiner();
}

// Exploded view
// =============

module exploded_view()
{
    dx = box_width + exploded_box_lid_distance;
    translate([ -dx / 2, 0, 0 ]) exploded_box();
    translate([ dx / 2, 0, 0 ]) exploded_lid();
}

module exploded_box()
{
    translate([ 0, -exploded_box_part_distance, 0 ]) box(0, 2, 6);
    box(2, 4, 6);
    translate([ 0, exploded_box_part_distance, 0 ]) box(4, 6, 6);
}

module exploded_lid()
{
    {
        translate([ 0, -1.5 * exploded_lid_part_distance, 0 ]) lid(0, 1, 6);
        translate([ 0, -0.5 * exploded_lid_part_distance, 0 ]) lid(1, 3, 6);
        translate([ 0, 0.5 * exploded_lid_part_distance, 0 ]) lid(3, 5, 6);
        translate([ 0, 1.5 * exploded_lid_part_distance, 0 ]) lid(5, 6, 6);
    }
}

// Connectors
// ==========

module split_model(start, end, units)
{
    assert(all_defined([ start, end, units ]));
    assert($children == 2);

    start_ratio = start / units;
    end_ratio = end / units;
    y_min = box_length * (start_ratio - 0.5);
    y_max = box_length * (end_ratio - 0.5);

    intersection()
    {
        union()
        {
            children(0);
            // Front joiners.
            if (start > 0)
                translate([ 0, y_min, 0 ]) children(1);
            // Back joiners.
            if (end < units)
                translate([ 0, y_max, 0 ]) children(1);
        }
        translate([ 0, (y_min + y_max) / 2, 0 ]) cube([ 1000, y_max - y_min, 1000 ], center = true);
    }
}

module joiner()
{
    difference()
    {
        joiner_full();
        joiner_screw_mask();
    }
}

module joiner_full()
{
    rotate([ 90, 0, 0 ]) linear_extrude(height = joiner_length, center = true) joiner_shape_2d();
}

module joiner_shape_2d()
{
    scale(joiner_width / 2) polygon(points = [ [ 1, 1 ], [ -1, 3 ], [ -1, -1 ], [ 1, -1 ] ]);
}

module joiner_screw_mask()
{
    joiner_screw_head_mask();
    joiner_screw_thread_mask();
    joiner_screw_nut_mask();
}

module joiner_screw_head_mask()
{
    translate([ 0, -joiner_length / 2, 0 ]) rotate([ 90, 0, 0 ]) translate([ 0, 0, 0.5 - screw_head_height / 2 ])
        screw_hole(height = screw_head_height + 1, width = screw_head_width, oversize = screw_head_oversize);
}

module joiner_screw_thread_mask()
{
    rotate([ 90, 0, 0 ])
        screw_hole(height = joiner_length, width = screw_thread_width, oversize = screw_thread_oversize);
}

module joiner_screw_nut_mask()
{
    translate([ 0, joiner_length / 2, 0 ]) rotate([ -90, 0, 0 ]) translate([ 0, 0, 0.5 - screw_nut_height / 2 ])
        nut_trap(height = screw_nut_height + 1, width = screw_nut_width, oversize = screw_nut_oversize);
}

// Screws
// ======

module screw_hole(height, width, oversize)
{
    assert(all_defined([ height, width, oversize ]));
    cylinder(h = height, r = (width + oversize) / 2, center = true, $fn = 50);
}

module nut_trap(height, width, oversize)
{
    assert(all_defined([ height, width, oversize ]));
    linear_extrude(height = height, center = true) hexagon(or = width / sqrt(3) + oversize / 2);
}

// 2D shapes
// =========

module rect(size, rounding = 0)
{
    assert(is_def(size));
    assert(rounding >= 0);
    if (rounding == 0)
        square(size = size, center = true);
    else
        hull() for (i = [ -1, 1 ], j = [ -1, 1 ])
        {
            x = i * (size.x / 2 - rounding);
            y = j * (size.y / 2 - rounding);
            translate([ x, y ]) circle(r = rounding);
        }
}

module hexagon(or)
{
    assert(is_def(or));
    circle(r = or, $fn = 6);
}

// 3D shapes
// =========

module rect_tube(height, size, wall, rounding = 0)
{
    assert(all_defined([ height, size, wall, rounding ]));
    linear_extrude(height = height)
    {
        isize = [ size.x - 2 * wall, size.y - 2 * wall ];
        irounding = rounding - wall;

        difference()
        {
            rect(size = size, rounding = rounding);
            rect(size = isize, rounding = irounding);
        }
    }
}

// Utilities
// =========

function is_def(x) = !is_undef(x);

function all_defined(v) = len([for (x = v) if (is_undef(x)) x]) == 0;
