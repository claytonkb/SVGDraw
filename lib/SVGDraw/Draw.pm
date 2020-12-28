package SVGDraw::Draw;

# This package is just a convenience-wrapper around https://metacpan.org/pod/SVG
# It is targeted to Inkscape. Tested on Inkscape 0.92

use strict;
use warnings;

use YAML;
use Data::Dumper;
use Exporter qw(import);
use SVG;

our @EXPORT_OK = qw(
    print_rect print_line print_text print_point open_svg close_svg show_drawbox
    open_layer close_layer init_canvas transform_coord transform_x_coord
    transform_y_coord drawbox_to_viewbox_x drawbox_to_viewbox_y plane_to_drawbox_x
    plane_to_drawbox_y drawbox_to_plane_x drawbox_to_plane_y viewbox_to_drawbox_x
    viewbox_to_drawbox_y print_rectxy );

# A bunch of routines for drawing SVG objects
#
# Normal SVG coordinates:
#   o-----------------> x
#   |
#   |
#   |
#   v
#   y
#
# The primitives use transform_x_coord, transform_y_coord to convert the coords
# to standard orientation:
#
#   ^
#   |
#   |
#   |
#   o-----------------> x
#   y
#

my $font_sizes = { # Note: These were derived from Inkscape's font-sizing
     8 =>  2.82,   #    but no idea how they are actually calculated...
    10 =>  3.53,
    12 =>  4.23,
    14 =>  4.94,
    16 =>  5.64,
    18 =>  6.34,
    20 =>  7.04,
    24 =>  8.44,
    28 =>  9.84,
    32 => 11.24,
    36 => 12.64,
    40 => 14.04,
    44 => 15.44,
    48 => 16.84 };

my $point_sizes = {
    'small' => 0.25, 
    'medium' => 0.4, 
    'large' => 0.5 };


sub print_rect{

    my $svg_canvas = shift;
    my ($x, $y, $width, $height, $options) = @_;
    my $svg = $svg_canvas->{svg};

    my $abs_width   = $width*$svg_canvas->{plane_scale_x};
    my $abs_height  = $height*$svg_canvas->{plane_scale_y};

    my $abs_x = transform_x_coord($svg_canvas, $x);
    my $abs_y = transform_y_coord($svg_canvas, $y) - $abs_height;
    #my $abs_y = transform_y_coord($svg_canvas, ($y + $height));

    my $stroke_color  = $svg_canvas->{rect_stroke_color};
    my $stroke_width  = $svg_canvas->{rect_stroke_width};
    my $shape_opacity = $svg_canvas->{rect_opacity};
    my $fill_color    = $svg_canvas->{rect_fill_color};

    if(defined $options){
        $stroke_color  = $options->{stroke_color} if exists $options->{stroke_color};
        $stroke_width  = $options->{stroke_width} if exists $options->{stroke_width};
        $shape_opacity = $options->{opacity}      if exists $options->{opacity};
        $fill_color    = $options->{fill_color}   if exists $options->{fill_color};
        if(exists $options->{abs}){
            $abs_x = $x;
            $abs_y = $y;
            $abs_width  = $width;
            $abs_height = $height;
        }
    }

#    my $tag = $svg->rectangle(
#        x      => $abs_x,
#        y      => $abs_y,
#        width  => $abs_width,
#        height => $abs_height,
#        style  => {
#            'stroke'         => $stroke_color,
#            'fill'           => $fill_color,
#            'stroke-width'   => $stroke_width,
#            'stroke-opacity' => $shape_opacity, #TODO: Unlink opacities...
#            'fill-opacity'   => $shape_opacity,
#        }
#    );

    my $tag = $svg->rectangle(
        x      => $abs_x,
        y      => $abs_y,
        width  => $width,
        height => $abs_height,
        style  => {
            'stroke'         => $stroke_color,
            'fill'           => $fill_color,
            'stroke-width'   => $stroke_width,
            'stroke-opacity' => $shape_opacity, #TODO: Unlink opacities...
            'fill-opacity'   => $shape_opacity,
        }
    );

    Draw_strprn($svg_canvas->{svg_string}, $tag->xmlify . "\n");
#    return $tag->xmlify;
#    return $svg->xmlify;

}

sub print_line{

    my $svg_canvas = shift;
    my ($start_x, $start_y, $end_x, $end_y, $options) = @_;
    my $svg = $svg_canvas->{svg};

    my $abs_start_x = transform_x_coord($svg_canvas, $start_x);
    my $abs_start_y = transform_y_coord($svg_canvas, $start_y);

    my $abs_end_x = transform_x_coord($svg_canvas, $end_x);
    my $abs_end_y = transform_y_coord($svg_canvas, $end_y);

    my $stroke_color  = $svg_canvas->{line_color};
    my $stroke_width  = $svg_canvas->{line_width};
    my $shape_opacity = $svg_canvas->{line_opacity};

    if(defined $options){
        $stroke_color  = $options->{color}   if exists $options->{color};
        $stroke_width  = $options->{width}   if exists $options->{width};
        $shape_opacity = $options->{opacity} if exists $options->{opacity};
        if(exists $options->{abs}){
            $abs_start_x = $start_x;
            $abs_start_y = $start_y;
            $abs_end_x = $end_x;
            $abs_end_y = $end_y;
        }
    }

    my $tag = $svg->line(
        x1     => $abs_start_x,
        y1     => $abs_start_y,
        x2     => $abs_end_x,
        y2     => $abs_end_y,
        style  => {
            'stroke'         => $stroke_color,
            'stroke-width'   => $stroke_width,
            'stroke-opacity' => $shape_opacity, #TODO: Unlink opacities...
        }
    );

    Draw_strprn($svg_canvas->{svg_string}, $tag->xmlify . "\n");

}


sub print_text{

    my $svg_canvas = shift;
    my $text = shift;
    my ($x, $y, $options) = @_;
    my $svg = $svg_canvas->{svg};

    my $abs_x = transform_x_coord($svg_canvas, $x);
    my $abs_y = transform_y_coord($svg_canvas, $y);

    my $text_size     = $font_sizes->{$svg_canvas->{font_size}};
    my $fill_color  = $svg_canvas->{text_color};
    my $shape_opacity = $svg_canvas->{shape_opacity};

    if(defined $options){
        $text_size     = $font_sizes->{$options->{size}} if exists $options->{size};
        $fill_color  = $options->{color}               if exists $options->{color};
        $shape_opacity = $options->{opacity}             if exists $options->{opacity};
        $abs_x         = $x                              if exists $options->{abs};
        $abs_y         = $y                              if exists $options->{abs};
    }

    my $tag = $svg->text(
        x      => $abs_x,
        y      => $abs_y,
        -cdata => "$text",
        style  => {
            'fill'           => $fill_color,
            'fill-opacity'   => $shape_opacity,
            'font-size'      => $text_size,
#            'stroke-width'   => $stroke_width,
#            'stroke-opacity' => $shape_opacity,
        }
    );
 
    Draw_strprn($svg_canvas->{svg_string}, $tag->xmlify . "\n");

}


sub print_point{

    my $svg_canvas = shift;
    my ($x, $y, $options) = @_;
    my $svg = $svg_canvas->{svg};

    my $abs_x = transform_x_coord($svg_canvas, $x);
    my $abs_y = transform_y_coord($svg_canvas, $y);

#    my $abs_x = drawbox_to_viewbox_x($svg_canvas, plane_to_drawbox_x($svg_canvas, $x));
#    my $abs_y = drawbox_to_viewbox_y($svg_canvas, plane_to_drawbox_y($svg_canvas, $y));

    my $color = $svg_canvas->{point_color};
    my $shape_opacity = $svg_canvas->{point_opacity};
    my $radius = $point_sizes->{'medium'};

    if(defined $options){
        $color         = $options->{color}                if exists $options->{color};
        $shape_opacity = $options->{opacity}              if exists $options->{opacity};
        $radius        = $SVGDraw::Draw::point_sizes->{$options->{size}} if exists $options->{size}; # small = 0.25, medium = 0.4, large = 0.5
        $radius        = $options->{radius}               if exists $options->{radius}; # caller knows what they want...
    }

    my $tag = $svg->circle(
        cx => $abs_x,
        cy => $abs_y,
        r =>  $radius,
        style => {
            'fill'           => $color,
            'fill-opacity'   => $shape_opacity,
        });

    Draw_strprn($svg_canvas->{svg_string}, $tag->xmlify . "\n");

}


sub open_svg{

    my $svg_canvas = shift;

    my $width  = $svg_canvas->{viewbox_width};
    my $height = $svg_canvas->{viewbox_height};

    my $viewbox_ULx = $svg_canvas->{viewbox_ULx};
    my $viewbox_ULy = $svg_canvas->{viewbox_ULy};
    my $viewbox_LRx = $svg_canvas->{viewbox_LRx};
    my $viewbox_LRy = $svg_canvas->{viewbox_LRy};

my $svg_header = <<"HEADER";
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg
   xmlns:dc="http://purl.org/dc/elements/1.1/"
   xmlns:cc="http://creativecommons.org/ns#"
   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
   xmlns:svg="http://www.w3.org/2000/svg"
   xmlns="http://www.w3.org/2000/svg"
   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
   height="${height}mm"
   width="${width}mm"
   viewBox="$viewbox_ULx $viewbox_ULy $viewbox_LRx $viewbox_LRy"
   version="1.1">
HEADER

    Draw_strprn($svg_canvas->{svg_string}, $svg_header);

}

sub close_svg{

    my $svg_canvas = shift;

my $svg_footer = <<"FOOTER";
</svg>
FOOTER

    Draw_strprn($svg_canvas->{svg_string}, $svg_footer);

}


sub show_drawbox{

    my $svg_canvas = shift;
    my $options = shift;
    my $svg = $svg_canvas->{svg};

    my $shape_opacity  = 1;
    my $fill_color     = '#e0e0e0';
    my $stroke_color   = '#202020';
    my $stroke_width   = 0.25;

    if(defined $options){
        $stroke_color  = "$options->{stroke_color}" if exists $options->{stroke_color};
        $fill_color    = "$options->{fill_color}"   if exists $options->{fill_color};
        $shape_opacity = $options->{opacity}        if exists $options->{opacity};
        $stroke_width  = $options->{stroke_width}   if exists $options->{stroke_width};
    }

    my $width  = $svg_canvas->{drawbox_width};
    my $height = $svg_canvas->{drawbox_height};
    my $x      = $svg_canvas->{drawbox_LLx};
    my $y      = $svg_canvas->{drawbox_URy};

    my $tag = $svg->rectangle(
        x      => $x,
        y      => $y,
        width  => $width,
        height => $height,
        style  => {
            'stroke'         => $stroke_color,
            'fill'           => $fill_color,
            'stroke-opacity' => $shape_opacity, #TODO: Unlink opacities...
            'fill-opacity'   => $shape_opacity,
            'stroke-width'   => $stroke_width,
        }
    );

    Draw_strprn($svg_canvas->{svg_string}, $tag->xmlify . "\n");

}

sub open_layer{

    my $svg_canvas = shift;
    my $layer_name = shift;

    die("Cannot open nested layer") if $svg_canvas->{layer_open};
    $svg_canvas->{layer_open} = 1;
    $svg_canvas->{current_layer}++;

    my $layer = $svg_canvas->{current_layer};
    $layer_name = "Layer $layer" if(!defined $layer_name);

my $layer_text = <<"END_LAYER";
<g
inkscape:groupmode="layer"
id="layer$layer"
inkscape:label="$layer_name">
END_LAYER

    Draw_strprn($svg_canvas->{svg_string}, "$layer_text\n");

}

sub close_layer{

    my $svg_canvas = shift;
    $svg_canvas->{layer_open} = 0;

    Draw_strprn($svg_canvas->{svg_string}, "</g>\n");

}

sub init_canvas{

    # general settings are overriden by more specific settings...
    my $svg_canvas                   = shift;
    my $options                      = shift;

    $svg_canvas->{viewbox_width}     = 300;
    $svg_canvas->{viewbox_height}    = 200;

    $svg_canvas->{drawbox_xmargin}   = 20;
    $svg_canvas->{drawbox_ymargin}   = 20;

    $svg_canvas->{plane_scale_x}     = 1;
    $svg_canvas->{plane_scale_y}     = 1;
    $svg_canvas->{plane_trans_x}     = 0;
    $svg_canvas->{plane_trans_y}     = 0;

    $svg_canvas->{hcenter}           = 0;
    $svg_canvas->{vcenter}           = 0;

    $svg_canvas->{fill_color}        = "#c0c0c0";
    $svg_canvas->{stroke_color}      = "#404040";
    $svg_canvas->{stroke_width}      = 0.25;
    $svg_canvas->{shape_opacity}     = 1;
    $svg_canvas->{font_size}         = 12;

    $svg_canvas->{current_layer}     = 0;
    $svg_canvas->{layer_open}        = 0;

    $svg_canvas->{point_opacity}     = $svg_canvas->{shape_opacity};
    $svg_canvas->{line_opacity}      = $svg_canvas->{shape_opacity};
    $svg_canvas->{rect_opacity}      = $svg_canvas->{shape_opacity};
    $svg_canvas->{text_opacity}      = $svg_canvas->{shape_opacity};

    $svg_canvas->{line_color}        = $svg_canvas->{stroke_color};
    $svg_canvas->{rect_stroke_color} = $svg_canvas->{stroke_color};

    $svg_canvas->{point_color}       = $svg_canvas->{fill_color};
    $svg_canvas->{rect_fill_color}   = $svg_canvas->{fill_color};
    $svg_canvas->{text_color}        = $svg_canvas->{fill_color};

    $svg_canvas->{line_width}        = $svg_canvas->{stroke_width};
    $svg_canvas->{rect_stroke_width} = $svg_canvas->{stroke_width};

    if(defined $options){ # override defaults
        for(keys %{$options}){
            $svg_canvas->{$_} = $options->{$_};
        }
    }    

    my $svg = SVG->new( width => $svg_canvas->{viewbox_width}, height => $svg_canvas->{viewbox_height});
    $svg_canvas->{svg} = $svg;

    $svg_canvas->{svg_string} = "";

    # These values are calculated by init_canvas() and should not be overridden
    $svg_canvas->{viewbox_ULx}       = 0;
    $svg_canvas->{viewbox_ULy}       = 0;
    $svg_canvas->{viewbox_LRx}       = $svg_canvas->{viewbox_ULx} + $svg_canvas->{viewbox_width};
    $svg_canvas->{viewbox_LRy}       = $svg_canvas->{viewbox_ULy} + $svg_canvas->{viewbox_height};

    $svg_canvas->{drawbox_LLx}       = $svg_canvas->{viewbox_ULx} + $svg_canvas->{drawbox_xmargin};
    $svg_canvas->{drawbox_LLy}       = $svg_canvas->{viewbox_LRy} - $svg_canvas->{drawbox_ymargin};
    $svg_canvas->{drawbox_URx}       = $svg_canvas->{viewbox_LRx} - $svg_canvas->{drawbox_xmargin};
    $svg_canvas->{drawbox_URy}       = $svg_canvas->{viewbox_ULy} + $svg_canvas->{drawbox_ymargin};

    $svg_canvas->{drawbox_height}    = $svg_canvas->{viewbox_height} - 2*$svg_canvas->{drawbox_ymargin};
    $svg_canvas->{drawbox_width}     = $svg_canvas->{viewbox_width}  - 2*$svg_canvas->{drawbox_xmargin};

    #NOTE: "plane" is the drawing plane where coordinates from the domain of interest exist
    $svg_canvas->{plane_trans_x}     = ($svg_canvas->{drawbox_width} /2) if $svg_canvas->{hcenter}; # NOTE: These can be overridden below!
    $svg_canvas->{plane_trans_y}     = ($svg_canvas->{drawbox_height}/2) if $svg_canvas->{vcenter};

    #NOTE: These calculate the extents of the viewbox in plane-space ...
    #       useful for setting up the coordinate-axes
    $svg_canvas->{plane_viewbox_LLx} = (0 - $svg_canvas->{plane_trans_x}) / $svg_canvas->{plane_scale_x};
    $svg_canvas->{plane_viewbox_URx} = ($svg_canvas->{drawbox_width} - $svg_canvas->{plane_trans_x}) / $svg_canvas->{plane_scale_x};
    $svg_canvas->{plane_viewbox_URy} = ((-1 * (                                 $svg_canvas->{drawbox_ymargin}  - $svg_canvas->{viewbox_height} + $svg_canvas->{drawbox_ymargin})) - $svg_canvas->{plane_trans_y}) / $svg_canvas->{plane_scale_y};
    $svg_canvas->{plane_viewbox_LLy} = ((-1 * (($svg_canvas->{drawbox_height} + $svg_canvas->{drawbox_ymargin}) - $svg_canvas->{viewbox_height} + $svg_canvas->{drawbox_ymargin})) - $svg_canvas->{plane_trans_y}) / $svg_canvas->{plane_scale_y};

}

# transforms an xy coordinate pair: [x, y]
sub transform_coord{

    my $svg_canvas = shift;
    my $xy_coord   = shift;

    return [ transform_x_coord($xy_coord->[0]), transform_y_coord($xy_coord->[1]) ];

}

sub transform_x_coord{

    my $svg_canvas = shift;
    my $x_coord    = shift;

    return drawbox_to_viewbox_x($svg_canvas, plane_to_drawbox_x($svg_canvas, $x_coord));

}

sub transform_y_coord{

    my $svg_canvas = shift;
    my $y_coord    = shift;

    return drawbox_to_viewbox_y($svg_canvas, plane_to_drawbox_y($svg_canvas, $y_coord));

}

sub drawbox_to_viewbox_x{ # translates from viewbox coordinates to drawbox coordinates

    my $svg_canvas = shift;
    my $x_coord    = shift;
    return ($x_coord + $svg_canvas->{drawbox_xmargin});

}

sub drawbox_to_viewbox_y{

    my $svg_canvas = shift;
    my $y_coord    = shift;
    return (-1 * $y_coord) + $svg_canvas->{viewbox_height} - $svg_canvas->{drawbox_ymargin};

}

sub viewbox_to_drawbox_x{

    my $svg_canvas = shift;
    my $x_coord    = shift;
    return ($x_coord - $svg_canvas->{drawbox_xmargin});

}

sub viewbox_to_drawbox_y{

    my $svg_canvas = shift;
    my $y_coord    = shift;
    return -1 * ($y_coord - $svg_canvas->{viewbox_height} + $svg_canvas->{drawbox_ymargin});

}

sub plane_to_drawbox_x{

    my $svg_canvas = shift;
    my $x_coord    = shift;

    return ($x_coord * $svg_canvas->{plane_scale_x}) + $svg_canvas->{plane_trans_x};

}

sub plane_to_drawbox_y{

    my $svg_canvas = shift;
    my $y_coord    = shift;

    return ($y_coord * $svg_canvas->{plane_scale_y}) + $svg_canvas->{plane_trans_y};

}

sub drawbox_to_plane_x{ # translates from plane coordinates to drawbox coordinates

    my $svg_canvas = shift;
    my $x_coord    = shift;

    return ($x_coord - $svg_canvas->{plane_trans_x}) / $svg_canvas->{plane_scale_x};

}

sub drawbox_to_plane_y{

    my $svg_canvas = shift;
    my $y_coord    = shift;

    return ($y_coord - $svg_canvas->{plane_trans_y}) / $svg_canvas->{plane_scale_y};

}

sub Draw_strprn{ $_[0] .= $_[1]; }


# Clayton Bauman 2020

1;

