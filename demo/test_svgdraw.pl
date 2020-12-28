#!/usr/bin/perl

use strict;

use YAML;
use Text::CSV qw( csv );
use File::Basename qw(dirname);
use Cwd  qw(abs_path);
use lib dirname(abs_path $0) . '/lib';
use SVGDraw::Draw qw(
    print_rect print_line print_text print_point open_svg close_svg show_drawbox
    open_layer close_layer init_canvas transform_coord transform_x_coord
    transform_y_coord );

my $svg_canvas = {};

init_canvas($svg_canvas);

open_svg($svg_canvas);

open_layer($svg_canvas, "Drawbox");
show_drawbox($svg_canvas);
close_layer($svg_canvas);

open_layer($svg_canvas);
print_rect($svg_canvas,  20,  40,  60,  80, {'opacity' => 0.5});
print_text($svg_canvas, "foobar", 70, 50, {'color' => '#ff0000', 'size' => 48, 'opacity' => 0.5});
close_layer($svg_canvas);

open_layer($svg_canvas);
for(1..15){
    print_line($svg_canvas, 0, $_*10, 260, $_*10, {'color' => '#00ff00', 'width' => (0.25 + ($_*0.05)), 'opacity' => 0.5, 'arrow_start' => ($_ % 2)});
}

close_layer($svg_canvas);

open_layer($svg_canvas);
for(1..25){
    print_line($svg_canvas, $_*10, 0, $_*10, 160, {'color' => '#0000ff', 'width' => (0.25 + ($_*0.05)), 'opacity' => 0.5}, 'arrow_end' => ($_ % 2));
}
close_layer($svg_canvas);

open_layer($svg_canvas, "Points");

for(1..15){
    print_point($svg_canvas,  10*$_, 20+40*log($_), {'color' => '#ff0000'});
}

close_layer($svg_canvas);

close_svg();

print $svg_canvas->{svg_string};

# Clayton Bauman 2020

