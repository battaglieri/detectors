use strict;
use warnings;

our %configuration;
our %parameters;

# number of mirrors
my $nmirrors = $parameters{"nmirrors"} ;

# hyperbola center
my @centerx = ();
my @centery = ();


# hyperbola tilt
my @alpha = ();

# edge point for all CC section
my @x21 = ();
my @y21 = ();

# hyperbola x minimum
my @hp_min = ();

# Mirrors width
my @mirror_width = ();

my @segtheta  = ();

sub calculateHypPars
{
	for(my $n=0; $n<$nmirrors ; $n++)
	{
		my $s = $n + 1;
		
		# hyperbola parameter
		my $a = $parameters{"ltcc.hypars.s$s.p0"};
		my $b = $parameters{"ltcc.hypars.s$s.p1"};
		my $c = $parameters{"ltcc.hypars.s$s.p2"};
		my $d = $parameters{"ltcc.hypars.s$s.p3"};
		my $f = $parameters{"ltcc.hypars.s$s.p4"};
		my $g = 1.0;
		
		
		# hyperbola center
		my $ddd = $c*$c - 4*$a*$b;
		$centerx[$n] = (2.0*$b*$d - $c*$f)/$ddd;
		$centery[$n] = (2.0*$a*$f - $c*$d)/$ddd;
		
		# hyperbola tilt
		$alpha[$n] = deg(0.5*$pi + 0.5*atan($c/($a - $b)));
		
		
		# edge point for all CC section
		$x21[$n] = $parameters{"ltcc.hy.s$s"."_x21"};
		$y21[$n] = $parameters{"ltcc.hy.s$s"."_y21"};
		
		# hyperbola x minimum
		$hp_min[$n] = $parameters{"ltcc.hy.s$s"."_xmin"};
		
		# hyperbola width
		$mirror_width[$n] = $parameters{"ltcc.hy.s$s"."_width"};
		
		# 90 - theta of center of hyp. segment
		$segtheta[$n] = 90 - $parameters{"ltcc.s$s"."_theta"};
		
		
		#print $y21[$n],  "\n";
	}
}


my $start_n = 1;
my $end_n   = 19;


# the hyperbolic mirrors are pgon with a number
# of sides dependent on their dimensions
sub build_hyp_mirrors
{
	
	for(my $n=$start_n; $n<$end_n; $n++)
	{
		my $m_width = $mirror_width[$n-1];
		
		# Modify number of sides here to make it more precise
		my $nsides = int(($x21[$n-1] - $hp_min[$n-1])/3) + 1 ;
		#my $nsides = 30 ;
		
		#print $n, "  length: ", $x21[$n-1] - $hp_min[$n-1], "  number of sides: ", $nsides, "\n";
		
		my @XPOS  = (1..$nsides);
		my @YPOS1 = (1..$nsides);
		my @YPOS2 = (1..$nsides);
		
		my $MINY = 9999;
		for(my $s=0; $s<$nsides; $s++)
		{
			my $dx = ($x21[$n-1] - $hp_min[$n-1])/$nsides;
			$XPOS[$s]  = $s*$dx;
			$YPOS1[$s] = calc_yp($hp_min[$n-1] + $s*$dx, $n-1);
			
			# Finding minimum
			if($YPOS1[$s] < $MINY) {$MINY=$YPOS1[$s];}
			
		}
		
		# We want to add thickness to the minimum
		my $YPOSSUB = -$m_width - 2;
		
		my $SUBY = $MINY + $YPOSSUB;
		
		my $YPOS0 =  $YPOSSUB + $y21[$n-1];
		
		
		for(my $s=0; $s<$nsides; $s++)
		{
			$YPOS1[$s] -= $SUBY;
			$YPOS2[$s] = $YPOS1[$s] + 1;  # mirror depth thickness
			#print " x: ", $XPOS[$s] , "  y1: " , $YPOS1[$s], "  y2: " , $YPOS2[$s], "\n";
		}
		
		
		my $dimensions = "45*deg 90*deg 1*counts $nsides*counts";
		for(my $s=0; $s<$nsides; $s++)
		{
			$dimensions = $dimensions ." $YPOS1[$s]*cm";
		}
		for(my $s=0; $s<$nsides; $s++)
		{
			$dimensions = $dimensions ." $YPOS2[$s]*cm";
		}
		for(my $s=0; $s<$nsides; $s++)
		{
			$dimensions = $dimensions ." $XPOS[$s]*cm";
		}
		
		
		
		# hyperbolic shape (full)
		my %detector = init_det();
		$detector{"name"}        = "hyperbolic_$n";
		$detector{"mother"}      = "root";
		$detector{"description"} = "LTCC Hyperbolic full shape $n";
		$detector{"type"}        = "Pgon";
		$detector{"dimensions"}  = "$dimensions";
		$detector{"material"}    = "Component";
		print_det(\%configuration, \%detector);
		
		# Right Box to subtract
		my $box_d = 100;
		my $xpos  = $m_width + $box_d;
		%detector = init_det();
		$detector{"name"}        = "right_sbox_$n";
		$detector{"mother"}      = "root";
		$detector{"description"} = "LTCC Hyperbolic mirror right subtract box $n";
		$detector{"pos"}         = "$xpos*cm 0*mm 0*cm";
		$detector{"type"}        = "Box";
		$detector{"dimensions"}  = "$box_d*cm $box_d*cm $box_d*cm";
		$detector{"material"}    = "Component";
		print_det(\%configuration, \%detector);
		
		# Left Box to subtract
		$xpos  = -$m_width - $box_d;
		%detector = init_det();
		$detector{"name"}        = "left_sbox_$n";
		$detector{"mother"}      = "root";
		$detector{"description"} = "LTCC Hyperbolic mirror left subtract box $n";
		$detector{"pos"}         = "$xpos*cm 0*mm 0*cm";
		$detector{"type"}        = "Box";
		$detector{"dimensions"}  = "$box_d*cm $box_d*cm $box_d*cm";
		$detector{"material"}    = "Component";
		print_det(\%configuration, \%detector);
		
		# Subtracting left box
		%detector = init_det();
		$detector{"name"}        = "hyperbolix_rbox_$n";
		$detector{"mother"}      = "root";
		$detector{"description"} = "LTCC Hyperbolic mirror right minus right box $n";
		$detector{"type"}        = "Operation: hyperbolic_$n - left_sbox_$n";
		$detector{"material"}    = "Air";
		$detector{"material"}    = "Component";
		print_det(\%configuration, \%detector);
		
		# Subtracting right box - RIGHT MIRROR
		%detector = init_det();
		$detector{"name"}        = "hyp_mirror_right_$n";
		$detector{"mother"}      = "segment_hyp_$n";
		$detector{"description"} = "LTCC Hyperbolic mirror right $n";
		$detector{"pos"}         = "$hp_min[$n-1]*cm $YPOS0*cm 0*cm";
		$detector{"rotation"}    = "0*deg -90*deg 0*deg";
		$detector{"color"}       = "aaffff";
		$detector{"type"}        = "Operation: hyperbolix_rbox_$n - right_sbox_$n";
		$detector{"material"}    = "Air";
		$detector{"style"}       = 1;
		$detector{"sensitivity"}    = "mirror: ltcc_AlMgF2";
		$detector{"hit_type"}       = "mirror";
		$detector{"identifiers"}    = "sector manual 1 type manual 2 side manual 1 segment manual $n";
		print_det(\%configuration, \%detector);
		
		# Subtracting right box - LEFT MIRROR
		%detector = init_det();
		$detector{"name"}        = "hyp_mirror_left_$n";
		$detector{"mother"}      = "segment_hyp_$n";
		$detector{"description"} = "LTCC Hyperbolic mirror right $n";
		$detector{"pos"}         = "-$hp_min[$n-1]*cm $YPOS0*cm 0*cm";
		$detector{"rotation"}    = "0*deg 90*deg 0*deg";
		$detector{"color"}       = "aaffff";
		$detector{"type"}        = "Operation: hyperbolix_rbox_$n - right_sbox_$n";
		$detector{"material"}    = "Air";
		$detector{"style"}       = 1;
		$detector{"sensitivity"}    = "mirror: ltcc_AlMgF2";
		$detector{"hit_type"}       = "mirror";
		$detector{"identifiers"}    = "sector manual 1 type manual 2 side manual 2 segment manual $n";
		print_det(\%configuration, \%detector);
		
		
		
		# Building the box that contains the mirrors (left and right)
		# Starts 1mm above x11
		my $segment_box_length    = $x21[$n-1] + 0.1;
		my $segment_box_thickness = $m_width + 0.1;
		my $yshift = 20;      # Should be enough to encompass all mirrrors
		my $segment_box_height    = $YPOS0 + $yshift;
		%detector = init_det();
		$detector{"name"}        = "segment_hyp_box_$n";;
		$detector{"mother"}      = "root";
		$detector{"description"} = "Light Threshold Cerenkov Counter HYP Segment Box $n";
		$detector{"color"}       = "880011";
		$detector{"type"}        = "Box";
		$detector{"dimensions"}  = "$segment_box_length*cm $segment_box_height*cm $segment_box_thickness*cm";
		$detector{"material"}    = "Component";
		print_det(\%configuration, \%detector);
		
		# Box to subract from  segment box
		# Starts at YPOS0
		my $s_segment_box_length    = $segment_box_length    + 0.2;
		my $s_segment_box_thickness = $segment_box_thickness + 0.2;
		my $s_segment_box_height    = $segment_box_height   ;
		%detector = init_det();
		$detector{"name"}        = "segment_hyp_subtract_box_$n";;
		$detector{"mother"}      = "root";
		$detector{"description"} = "Light Threshold Cerenkov Counter Segment Box to Subtract $n";
		$detector{"pos"}         = "0*cm -$yshift*cm 0*mm";
		$detector{"color"}       = "1100ff";
		$detector{"type"}        = "Box";
		$detector{"dimensions"}  = "$s_segment_box_length*cm $s_segment_box_height*cm $s_segment_box_thickness*cm";
		$detector{"material"}    = "Component";
		print_det(\%configuration, \%detector);
		
		
		%detector = init_det();
		$detector{"name"}        = "segment_hyp_$n";;
		$detector{"mother"}      = "ltcc";
		$detector{"description"} = "Light Threshold Cerenkov Counter HYP segment $n";
		#$detector{"mother"}      = "root";
		$detector{"rotation"}    = "-$segtheta[$n-1]*deg 0*deg 0*deg";
		$detector{"color"}       = "00ff11";
		$detector{"type"}        = "Operation: segment_hyp_box_$n - segment_hyp_subtract_box_$n";
		$detector{"material"}    = "C4F10";
		$detector{"visible"}     = 0;
		print_det(\%configuration, \%detector);
		
	}
}



sub calc_yp()
{
	my $x = shift;
	my $s = shift;
	
	$s += 1;
	
	my $p1 = $parameters{"ltcc.hypars.s$s.p0"};
	my $p2 = $parameters{"ltcc.hypars.s$s.p1"};
	my $p3 = $parameters{"ltcc.hypars.s$s.p2"};
	my $p4 = $parameters{"ltcc.hypars.s$s.p3"};
	my $p5 = $parameters{"ltcc.hypars.s$s.p4"};
	
	
	my $a = $p2;
	my $b = $p3*$x + $p5;
	my $c = 1 + $p1*$x*$x + $p4*$x;
	
	return (-$b - sqrt($b*$b-4*$a*$c))/(2*$a);
}




sub buildHypMirrors
{
	calculateHypPars();
	build_hyp_mirrors();
}






