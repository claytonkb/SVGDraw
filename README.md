SVGDraw
=======

This Perl module is a convenience-wrapper for SVG (`use SVG`). To test the
module, run the demo/test_draw.pl script in this repo. You will need to install
any modules from CPAN that are not present on your system (on Windows, use
the ppm; on Ubuntu-based distros, you can call `sudo cpan`).

In addition, you should add the DrawSVG library to your Perl installation. You
can do this the "official" way (however that looks for your system). Or, you can
just create a symbolic link to the lib folder in this repository. From ./demo,
run the command `ln -s ../lib lib` to create a symbolic link.

When you run the command `perl test_svgdraw.pl`, you should get a printing of
SVG to STDOUT. Just redirect this to some file, e.g. `perl test_svgdraw.pl > test.svg`.
Now, you can open and view the SVG file.

The .pm library is still incomplete. TODOs include a print_circle() function
and several other convenience functions. Stay tuned...

