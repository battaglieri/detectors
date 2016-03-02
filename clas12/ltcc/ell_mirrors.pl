use strict;
use warnings;

our %configuration;
our %parameters;

# number of mirrors
my $nmirrors = $parameters{"nmirrors"} ;


# All dimensions in cm
# The ellipse equation is
# p1*x**2 + p2*y**2 + p3*x*y + p4*x + p5*y + 1 = 0


# ellipse center
my @centerx = ();
my @centery = ();

# ellipse tilt
my @alpha = ();

# Axis Length
my @axisa = ();
my @axisb = ();

my @x12           = ();
my @y12           = ();
my @end_tocangle  = ();   # angle between the end of right segment and the center of the ellipse
my @sta_tocangle  = ();   # angle between the start of right segment and the center of the ellipse

my @y11           = ();

my @segtheta      = ();

# Mirrors width
my @mirror_width = ();


# mirrors are 1 cm thick
my $mirrors_thickness = 1;

my $start_n = 1;  # 1 - 18
my $end_n   = 19; # 2 - 19, greater than start_n


sub calculateEllPars
{
	for(my $n=0; $n<$nmirrors ; $n++)
	{
		my $s = $n + 1;
		
		# ellipse parameter
		my $a = $parameters{"ltcc.elpars.s$s.p0"};
		my $b = $parameters{"ltcc.elpars.s$s.p1"};
		my $c = $parameters{"ltcc.elpars.s$s.p2"};
		my $d = $parameters{"ltcc.elpars.s$s.p3"};
		my $f = $parameters{"ltcc.elpars.s$s.p4"};
		my $g = 1.0;
		
		
		# ellipse center
		$centerx[$n] = (2.0*$b*$d - $c*$f)/($c*$c - 4.0*$a*$b);
		$centery[$n] = (2.0*$a*$f - $c*$d)/($c*$c - 4.0*$a*$b);
		
		# ellipse tilt
		$alpha[$n] = deg(0.5*$pi + 0.5*atan($c/($a - $b)));
		
		# pd: parameters after shift
		# notation consistent with Alex Vlassov
		my $atcenter = $a*$centerx[$n]*$centerx[$n] + $b*$centery[$n]*$centery[$n]
		+ $c*$centerx[$n]*$centery[$n] + $d*$centerx[$n] + $f*$centery[$n] + 1.0;
		
		my $pd1 = $a/$atcenter;
		my $pd2 = $b/$atcenter;
		my $pd3 = $c/$atcenter;
		my $pd4 = ($d + $c*$centery[$n] + 2*$a*$centerx[$n])/$atcenter;
		my $pd5 = ($f + $c*$centerx[$n] + 2*$b*$centery[$n])/$atcenter;
		
		# print $pd1, " " , $pd2, " " , $pd3, " " , $pd4, " " , $pd5, "\n";
		
		
		# pc: parameters after rotation
		# notation consistent with Alex Vlassov
		my $cs = cos(rad(-$alpha[$n]));
		my $sn = sin(rad(-$alpha[$n]));
		
		my $pc1 = $pd1*$cs*$cs + $pd2*$sn*$sn - $pd3*$sn*$cs ;
		my $pc2 = $pd1*$sn*$sn + $pd2*$cs*$cs + $pd3*$sn*$cs ;
 		my $pc3 = 2.0*$sn*$cs*($pd1 - $pd2) + $pd3*($cs*$cs -$sn*$sn);
 		my $pc4 = $pd4*$cs - $pd5*$sn;
 		my $pc5 = $pd5*$cs + $pd4*$sn;
		
		#print $pc1, " " , $pc2, " " , $pc3, " " , $pc4, " " , $pc5, "\n";
		
		# calculating semi-axis, following Alex formalism
		my $skobka = 0.25*$pc4*$pc4/$pc1 + 0.25*$pc5*$pc5/$pc2 - 1.0;
		$axisa[$n] = sqrt( $skobka / $pc1);
		$axisb[$n] = sqrt( $skobka / $pc2);
		
		
		# span angles for ellipses
		$x12[$n] = $parameters{"ltcc.el.s$s"."_x12"};
		$y12[$n] = $parameters{"ltcc.el.s$s"."_y12"};
		
		# angle between end of segment E and
		# vertical line passing for center of the ellipse
		
		#  |     E
		#  |    /
		#  |   /
		#  |  /
		#  | C
		#  |/
		#  /
		# /|
		
		
		my $xloc2 = $x12[$n] - $centerx[$n];
		my $yloc2 = $y12[$n] - $centery[$n];
		$end_tocangle[$n] = 90 - (atan($yloc2/$xloc2))*180.0/$pi;
		
		
		# angle between start of segment O and
		# vertical line passing through center of the ellipse
		# for the first two ellipses it has negative sign
		
		# S  |
		#  \ |
		#   \|
		#    \
		#    |\
		#    | C
		
		$y11[$n] = $parameters{"ltcc.el.s$s"."_y11"};
		my $xloc1 = 0         - $centerx[$n];
		my $yloc1 = $y11[$n]  - $centery[$n];
		
		if($centerx[$n]<0) { $sta_tocangle[$n] =  -90 + (atan($yloc1/$xloc1))*180.0/$pi ; }
		if($centerx[$n]>0) { $sta_tocangle[$n] =   90 + (atan($yloc1/$xloc1))*180.0/$pi ; }
		
		
		
		# 90 - theta of center of ell. segment
		$segtheta[$n] = 90 - $parameters{"ltcc.s$s"."_theta"};
		
		# mirrors width
		$mirror_width[$n] = $parameters{"ltcc.el.s$s"."_width"};
		
		# print $sta_tocangle[$n], "\n";
	}
}


# Building the boxes that contains the mirrors (both left and right)
sub build_ell_mirrors_containers
{
	for(my $n=$start_n; $n<$end_n; $n++)
	{
		my $lcntx = -$centerx[$n-1];
		my $ralpha = 180 - $alpha[$n-1];
		my $lalpha =  $alpha[$n-1];
		
		# Starts 1mm above x11
		my $segment_box_length    = $x12[$n-1] + 0.1;
		my $segment_box_thickness = $mirror_width[$n-1] + 0.1;
		my $segment_box_height    = $y11[$n-1] + 5;   # Harcoded 5 mm to add to box
		if($y12[$n-1] > $y11[$n-1]) {$segment_box_height = $y12[$n-1] + 5;}
		
		my %detector = init_det();
		$detector{"name"}        = "segment_ell_box_$n";;
		$detector{"mother"}      = "root";
		$detector{"description"} = "Light Threshold Cerenkov Counter Segment Box $n";
		$detector{"type"}        = "Box";
		$detector{"dimensions"}  = "$segment_box_length*cm $segment_box_height*cm $segment_box_thickness*cm";
		$detector{"material"}    = "Component";
		print_det(\%configuration, \%detector);
		
		# Box to subract from  segment box
		# Starts 1mm below and to the right of end point x12, y12
		my $s_segment_box_length    = $segment_box_length    + 0.2;
		my $s_segment_box_thickness = $segment_box_thickness + 0.2;
		my $s_segment_box_height    = $segment_box_height   ;
		my $yshift = $segment_box_height - $y12[$n-1] + 0.2;
		if($y12[$n-1] > $y11[$n-1]) {$yshift = $segment_box_height - $y11[$n-1] + 0.2;}
		
		%detector = init_det();
		$detector{"name"}        = "segment_ell_subtract_box_$n";;
		$detector{"mother"}      = "root";
		$detector{"description"} = "Light Threshold Cerenkov Counter Segment Box to Subtract $n";
		$detector{"pos"}         = "0*cm -$yshift*cm 0*mm";
		$detector{"type"}        = "Box";
		$detector{"dimensions"}  = "$s_segment_box_length*cm $s_segment_box_height*cm $s_segment_box_thickness*cm";
		$detector{"material"}    = "Component";
		print_det(\%configuration, \%detector);
		
		# The subtraction is done so that the container
		# has the same coordinates as clas center
		%detector = init_det();
		$detector{"name"}        = "segment_ell_$n";;
		$detector{"mother"}      = "ltcc";
		$detector{"description"} = "Light Threshold Cerenkov Counter ELL segment $n";
		$detector{"rotation"}    = "-$segtheta[$n-1]*deg 0*deg 0*deg";
		$detector{"type"}        = "Operation: segment_ell_box_$n - segment_ell_subtract_box_$n";
		$detector{"material"}    = "C4F10";
		$detector{"visible"}     = 0;
		print_det(\%configuration, \%detector);
		
	}
}



# builds the complete elliptical shells, to be cut bu cheese forms later
sub build_ell_shells
{
	for(my $n=$start_n; $n<$end_n; $n++)
	{
		my $m_width = $mirror_width[$n-1];
		
		# outer shell
		my %detector = init_det();
		$detector{"name"}        = "el_outer_shell_$n";;
		$detector{"mother"}      = "root";
		$detector{"description"} = "Light Threshold Cerenkov Counter Mirror Outside $n";
		$detector{"type"}        = "EllipticalTube";
		$detector{"dimensions"}  = "$axisa[$n-1]*cm $axisb[$n-1]*cm $m_width*cm";
		$detector{"material"}    = "Air";
		$detector{"material"}    = "Component";
		print_det(\%configuration, \%detector);
		
		# inner shell
		my $maa = $axisa[$n-1] - $mirrors_thickness;
		my $mab = $axisb[$n-1] - $mirrors_thickness;
		my $ml  = $m_width + 1.0; # making the inner it 1 cm bigger so the subtraction is guaranteed
		%detector = init_det();
		$detector{"name"}        = "el_inner_shell_$n";;
		$detector{"mother"}      = "root";
		$detector{"description"} = "Light Threshold Cerenkov Counter Mirror Inside $n";
		$detector{"type"}        = "EllipticalTube";
		$detector{"dimensions"}  = "$maa*cm $mab*cm $ml*cm";
		$detector{"material"}    = "Air";
		$detector{"material"}    = "Component";
		print_det(\%configuration, \%detector);
		
		
		# The segment sits on the ellipse top half.
		# With no rotation that part is at negative x
		# (left part of the screen if looking upstream)
		# The right ellipse is rotated by 180 - alpha
		# because rotation angle starts from the positive x axis
		# The second one is the x-symmetric of the right one
		my $ralpha = 180 - $alpha[$n-1];
		my $lalpha =  $alpha[$n-1];
		
		# The ellipse tube in the segment reference system
		# is shifted to CENTER and then rotated around Z by -ALPHA
		# Since z is coming out of the page
		# Outer - Inner
		%detector = init_det();
		$detector{"name"}        = "ellipse_tube_right_$n";;
		$detector{"mother"}      = "root";
		$detector{"description"} = "Light Threshold Cerenkov Counter Mirror Frame $n";
		$detector{"pos"}         = "$centerx[$n-1]*cm $centery[$n-1]*cm 0*mm";
		$detector{"rotation"}    = "0*deg 0*deg $ralpha*deg";
		$detector{"type"}        = "Operation: el_outer_shell_$n - el_inner_shell_$n";
		$detector{"material"}    = "Air_Opt";
		$detector{"material"}    = "Component";
		print_det(\%configuration, \%detector);
		
		my $lcntx = -$centerx[$n-1];
		%detector = init_det();
		$detector{"name"}        = "ellipse_tube_left_$n";;
		$detector{"mother"}      = "root";
		$detector{"description"} = "Light Threshold Cerenkov Counter Mirror Frame $n";
		$detector{"pos"}         = "$lcntx*cm $centery[$n-1]*cm 0*mm";
		$detector{"rotation"}    = "0*deg 0*deg $lalpha*deg";
		$detector{"type"}        = "Operation: el_outer_shell_$n - el_inner_shell_$n";
		$detector{"material"}    = "Air_Opt";
		$detector{"material"}    = "Component";
		print_det(\%configuration, \%detector);
		
	}
}


sub build_check_ell_cheeseform
{
	for(my $n=$start_n; $n<$end_n; $n++)
	{
		my $lcntx = -$centerx[$n-1];

		# tube with MAX theta angle to subtract
		#
		# To visualize the correct subtraction, the check_tube is used
		# and placed in ROOT at 0,0 and no rotation
		#
		# Since the bolean operation takes place in the first volume
		# coordinate system one has to invert that transformation matrix
		# to have the correct subtraction

		# The tube span starting point is then the end point of the mirror

		my $tubespan   =  360 - ($end_tocangle[$n-1] + $sta_tocangle[$n-1]);
		my $starttheta_r = 90 + $sta_tocangle[$n-1];
		my $starttheta_l = 90 + $end_tocangle[$n-1];

		my %detector = init_det();
		$detector{"name"}        = "checktube_right_$n";
		$detector{"mother"}      = "root";
		$detector{"description"} = "Light Threshold Cerenkov Counter Mirror Tube with Max Theta $n";
		$detector{"pos"}         = "$centerx[$n-1]*cm $centery[$n-1]*cm 0*mm";
		$detector{"color"}       = "110088";
		$detector{"type"}        = "Tube";
		$detector{"dimensions"}  = "0*m 5*m 0.6*m $starttheta_r*deg $tubespan*deg";
		$detector{"material"}    = "Air";
		print_det(\%configuration, \%detector);

		%detector = init_det();
		$detector{"name"}        = "checktube_left_$n";;
		$detector{"mother"}      = "root";
		$detector{"description"} = "Light Threshold Cerenkov Counter Mirror Tube with Max Theta $n";
		$detector{"pos"}         = "$lcntx*cm $centery[$n-1]*cm 0*mm";
		$detector{"color"}       = "880011";
		$detector{"type"}        = "Tube";
		$detector{"dimensions"}  = "0*m 5*m 0.6*m $starttheta_l*deg $tubespan*deg";
		$detector{"material"}    = "Air";
		print_det(\%configuration, \%detector);
	}
}

sub build_ell_mirrors
{
	for(my $n=$start_n; $n<$end_n; $n++)
	{
		my $lcntx = -$centerx[$n-1];
		my $ralpha = 180 - $alpha[$n-1];
		my $lalpha =  $alpha[$n-1];
		
		
		# Adding 0.1 deg to avoid overlaps
		my $cralpha = $ralpha + 0.01;
		my $clalpha = $lalpha - 0.01;
		
		my $tubespan   =  360 - ($end_tocangle[$n-1] + $sta_tocangle[$n-1]);
		my $starttheta_r = 90 + $sta_tocangle[$n-1];
		my $starttheta_l = 90 + $end_tocangle[$n-1];
		
		
		my %detector = init_det();
		$detector{"name"}        = "span_tube_right_$n";;
		$detector{"mother"}      = "root";
		$detector{"description"} = "Light Threshold Cerenkov Counter Mirror Tube with Max Theta - RIGHT segment $n";
		$detector{"rotation"}    = "0*deg 0*deg -$ralpha*deg";
		$detector{"color"}       = "110088";
		$detector{"type"}        = "Tube";
		$detector{"dimensions"}  = "0*m 5*m 0.6*m $starttheta_r*deg $tubespan*deg";
		$detector{"material"}    = "Air";
		$detector{"material"}    = "Component";
		$detector{"style"}       = 1;
		print_det(\%configuration, \%detector);
		
		
		%detector = init_det();
		$detector{"name"}        = "span_tube_left_$n";;
		$detector{"mother"}      = "root";
		$detector{"description"} = "Light Threshold Cerenkov Counter Mirror Tube with Max Theta - LEFT segment $n";
		$detector{"rotation"}    = "0*deg 0*deg -$lalpha*deg";
		$detector{"color"}       = "880011";
		$detector{"type"}        = "Tube";
		$detector{"dimensions"}  = "0*m 5*m 0.6*m $starttheta_l*deg $tubespan*deg";
		$detector{"material"}    = "Air";
		$detector{"material"}    = "Component";
		$detector{"style"}       = 1;
		print_det(\%configuration, \%detector);
		
		
		# Subtract tube
		# The order translation/rotation is irrelevant since
		# the rotation is around Z and translation is in XY plane
		
		# mirror RIGHT
		%detector = init_det();
		$detector{"name"}        = "el_mir_right_$n";;
		$detector{"mother"}      = "segment_ell_$n";
		$detector{"description"} = "LTCC Right Mirror $n";
		$detector{"pos"}         = "$centerx[$n-1]*cm $centery[$n-1]*cm 0*mm";
		$detector{"rotation"}    = "0*deg 0*deg $cralpha*deg";
		$detector{"color"}       = "aaffff";
		$detector{"type"}        = "Operation: ellipse_tube_right_$n - span_tube_right_$n ";
		$detector{"dimensions"}  = "0*m";
		$detector{"material"}    = "Air_Opt";
		$detector{"style"}       = 1;
		$detector{"visible"}     = 1; #nate
		$detector{"sensitivity"}    = "mirror: ltcc_AlMgF2";
		$detector{"hit_type"}       = "mirror";
		$detector{"identifiers"}    = "sector manual 1 type manual 1 side manual 1 segment manual $n";
		print_det(\%configuration, \%detector);
		
		# mirror LEFT
		%detector = init_det();
		$detector{"name"}        = "el_mir_left_$n";;
		$detector{"mother"}      = "segment_ell_$n";
		$detector{"description"} = "LTCC Left Mirror $n";
		$detector{"pos"}         = "$lcntx*cm $centery[$n-1]*cm 0*mm";
		$detector{"rotation"}    = "0*deg 0*deg $clalpha*deg";
		$detector{"color"}       = "aaffff";
		$detector{"type"}        = "Operation: ellipse_tube_left_$n - span_tube_left_$n ";
		$detector{"dimensions"}  = "0*m";
		$detector{"material"}    = "Air_Opt";
		$detector{"mfield"}      = "no";
		$detector{"style"}       = 1;
		$detector{"visible"}     = 1; #nate
		$detector{"sensitivity"}    = "mirror: ltcc_AlMgF2";
		$detector{"hit_type"}       = "mirror";
		$detector{"identifiers"}    = "sector manual 1 type manual 1 side manual 2 segment manual $n";
		print_det(\%configuration, \%detector);
		
	}
}




sub buildEllMirrors
{
	calculateEllPars();
	build_ell_mirrors_containers();
	
	build_ell_shells();
	
	# the cheese forms to check
	# comment out after debugging
	# build_check_ell_cheeseform();
	
	# mirrors are cut from ell shells
	# with the cheese forms
	build_ell_mirrors();
	
	# focal point spheres
}







