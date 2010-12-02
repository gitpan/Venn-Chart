package Venn::Chart;

use warnings;
use strict;
use Carp;

#==================================================================
# Author    : Djibril Ousmanou
# Copyright : 2010
# Update    : 02/12/2010 09:53:38
# AIM       : Create a Venn diagram image
#==================================================================

use GD;
use GD::Graph::hbars;
use GD::Graph::colour;
use GD::Text::Align;
use List::Compare;

use vars qw($VERSION);
$VERSION = '1.01';

my %default = (
  Hlegend => 70,
  Htitle  => 30,
  space   => 10,
  colors  => [ [ 189, 66, 238, 0 ], [ 255, 133, 0, 0 ], [ 0, 107, 44, 0 ] ],
);

sub new {
  my ( $self, $width, $height ) = @_;

  $self = ref($self) || $self;
  my $this = {};
  bless( $this, $self );

  $this->{_width}  = $width  || 500;
  $this->{_height} = $height || 500;
  $this->{_dim}{Ht}         = 0;
  $this->{_dim}{HLeg}       = 0;
  $this->{_dim}{space}      = $default{space};
  $this->{_colors}          = $default{colors};
  $this->{_circles}{number} = 0;
  $this->{_legends}{number} = 0;

  return $this;
}

sub set {
  my ( $this, %param ) = @_;
  $this->{_colors} = $param{'-colors'} || $default{colors};

  if ( exists $param{'-title'} ) {
    $this->{_title} = $param{'-title'};
    $this->{_dim}{Ht} = $default{Htitle};
  }
  return 1;
}

sub set_legends {
  my ( $this, @legends ) = @_;
  $this->{_legends}{number} = scalar @legends;

  unless ( $this->{_legends}{number} == 2 or $this->{_legends}{number} == 3 ) {
    carp("You must set 2 or 3 legends");
    return;
  }

  $this->{_legend} = \@legends;
  $this->{_dim}{HLeg} = $default{Hlegend};

  return 1;
}

sub _legend {
  my ( $this, $image ) = @_;

  # Coords
  my $cubex1 = $default{space};
  my $cubey1 = $this->{_dim}{Ht} + $this->{_dim}{Hc} + 10;
  my $cubex2 = $cubex1 + 10;
  my $cubey2 = $cubey1 + 10;
  my $xtext  = $cubex2 + 10;
  my $ytext  = $cubey1;

  for ( 0 .. 2 ) {
    my $idcolor = $_ + 1;
    last unless ( $this->{_legend}->[$_] and $this->{_conf_color}{"color$idcolor"} );
    $image->filledRectangle( $cubex1, $cubey1, $cubex2, $cubey2, $this->{_conf_color}{"color$idcolor"} );
    $image->string( gdMediumBoldFont, $xtext, $ytext, $this->{_legend}->[$_], $this->{_conf_color}{black} );
    $cubey1 = $cubey2 + 10;
    $cubey2 = $cubey1 + 10;
    $ytext  = $cubey1;
  }

  return 1;
}

sub plot {
  my ( $this, @data ) = @_;
  $this->{_circles}{number} = scalar @data;
  unless ( $this->{_circles}{number} == 2 or $this->{_circles}{number} == 3 ) {
    croak("You must plot 2 or 3 lists");
  }

  $this->{_dim}{R} = ( $this->{_width} - ( 2 * $this->{_dim}{space} ) ) / 3;
  $this->{_dim}{D} = $this->{_dim}{R} * 2;

  # Check Height dimension and recalcul space
  my $diff
    = ( $this->{_dim}{Ht} + $this->{_dim}{D} + $this->{_dim}{R} + $this->{_dim}{HLeg} - $this->{_height} );
  if ( $diff > 0 ) {
    $this->{_dim}{space} += ( $diff / 2 );
    $this->{_dim}{R} = ( $this->{_width} - ( 2 * $this->{_dim}{space} ) ) / 3;
    $this->{_dim}{D} = $this->{_dim}{R} * 2;
  }

  my $image = new GD::Image( $this->{_width}, $this->{_height} );

  $this->{_conf_color}{white} = $image->colorAllocate( 255, 255, 255 );
  $this->{_conf_color}{black} = $image->colorAllocate( 0,   0,   0 );

  # make the background transparent and interlaced
  $image->transparent( $this->{_conf_color}{white} );
  $image->interlaced('true');

  # display circle
  $this->_title($image) if ( $this->{_title} );
  $this->_circle( $image, @data );
  $this->_legend($image) if ( $this->{_legend} );

  $this->{_gd}{plot} = $image;

  return $image;
}

sub _title {
  my ( $this, $image ) = @_;

  return unless defined $image;

  $this->{_coords}{xtitle} = $this->{_dim}{space};
  $this->{_coords}{ytitle} = $this->{_dim}{Ht} / 2;

  my $align = GD::Text::Align->new(
    $image,
    valign => 'center',
    halign => 'center',
    colour => $this->{_conf_color}{black},
  );

  $align->set_font(gdMediumBoldFont);
  $align->set_text( $this->{_title} );
  $align->draw( $this->{_width} / 2, $this->{_coords}{ytitle}, 0 );

  return 1;
}

sub _circle {
  my ( $this, $image, $ref_data1, $ref_data2, $ref_data3 ) = @_;
  return unless defined $image;

  # Venn with 2 circles
  # Coords
  $this->{_coords}{xc1} = $this->{_dim}{space} + $this->{_dim}{R};
  $this->{_coords}{yc1} = $this->{_dim}{R} + $this->{_dim}{Ht};

  $this->{_coords}{xc2} = $this->{_coords}{xc1} + $this->{_dim}{R};
  $this->{_coords}{yc2} = $this->{_coords}{yc1};

  # display circles
  $image->arc(
    $this->{_coords}{xc1},
    $this->{_coords}{yc1},
    $this->{_dim}{D},
    $this->{_dim}{D},
    0, 360, $this->{_conf_color}{black}
  );
  $image->arc(
    $this->{_coords}{xc2},
    $this->{_coords}{yc2},
    $this->{_dim}{D},
    $this->{_dim}{D},
    0, 360, $this->{_conf_color}{black}
  );

  # text circle
  my $lcm     = List::Compare->new( { lists => [ $ref_data1, $ref_data2, $ref_data3 ], } );
  my @list1   = $lcm->get_unique(0);
  my $data1   = scalar(@list1);
  my @list2   = $lcm->get_unique(1);
  my $data2   = scalar(@list2);
  my @list3   = $lcm->get_unique(2);
  my $data3   = scalar(@list3);
  my @list123 = $lcm->get_intersection;
  my $data123 = scalar(@list123);

  my $lc     = List::Compare->new( $ref_data1, $ref_data2 );
  my @list12 = $lc->get_intersection;
  my $lc12   = List::Compare->new( \@list12, \@list123 );
  @list12 = $lc12->get_unique;
  my $data12 = scalar(@list12);

  $lc = List::Compare->new( $ref_data1, $ref_data3 );
  my @list13 = $lc->get_intersection;
  my $lc13 = List::Compare->new( \@list13, \@list123 );
  @list13 = $lc13->get_unique;
  my $data13 = scalar(@list13);

  $lc = List::Compare->new( $ref_data2, $ref_data3 );
  my @list23 = $lc->get_intersection;
  my $lc23 = List::Compare->new( \@list23, \@list123 );
  @list23 = $lc23->get_unique;
  my $data23 = scalar(@list23);

  # for get_regions
  $this->{_regions} = [ $data1, $data2, $data12 ];
  $this->{_listregions} = [ \@list1, \@list2, \@list12 ];

  $this->{_coords}{xt1} = $this->{_dim}{space} + ( $this->{_dim}{R} / 3 );
  $this->{_coords}{yt1} = $this->{_coords}{yc1};

  $this->{_coords}{xt2} = $this->{_dim}{space} + $this->{_dim}{D} + ( $this->{_dim}{R} / 3 );
  $this->{_coords}{yt2} = $this->{_coords}{yc1};

  $this->{_coords}{xt12} = $this->{_coords}{xc1} + ( $this->{_dim}{R} / 2 );
  $this->{_coords}{yt12} = $this->{_coords}{yc1} - ( $this->{_dim}{R} / 2 );

  if ( $this->{_colors}->[0] and $this->{_colors}->[1] ) {
    $this->{_conf_color}{color1} = $image->colorAllocateAlpha( @{ $this->{_colors}->[0] } );
    $this->{_conf_color}{color2} = $image->colorAllocateAlpha( @{ $this->{_colors}->[1] } );
    my $ref_color12 = $this->_moy_color( $this->{_colors}->[0], $this->{_colors}->[1] );
    $this->{_conf_color}{color12} = $image->colorAllocateAlpha( @{$ref_color12} );

    $image->fill( $this->{_coords}{xt1},  $this->{_coords}{yt1},  $this->{_conf_color}{color1} );
    $image->fill( $this->{_coords}{xt2},  $this->{_coords}{yt2},  $this->{_conf_color}{color2} );
    $image->fill( $this->{_coords}{xt12}, $this->{_coords}{yt12}, $this->{_conf_color}{color12} );

    $this->{_colors_regions} = [ $this->{_colors}->[0], $this->{_colors}->[1], $ref_color12 ];
  }
  $image->string( gdMediumBoldFont,
    $this->{_coords}{xt1},
    $this->{_coords}{yt1},
    $data1, $this->{_conf_color}{black}
  );
  $image->string( gdMediumBoldFont,
    $this->{_coords}{xt2},
    $this->{_coords}{yt2},
    $data2, $this->{_conf_color}{black}
  );
  $image->string( gdMediumBoldFont,
    $this->{_coords}{xt12},
    $this->{_coords}{yt12},
    $data12, $this->{_conf_color}{black}
  );
  $this->{_dim}{Hc} = $this->{_dim}{D};

  # Venn with 3 circles
  if ( defined $ref_data3 ) {
    $this->{_coords}{xc3} = $this->{_coords}{xc1} + ( $this->{_dim}{R} / 2 );
    $this->{_coords}{yc3} = $this->{_coords}{yc1} + $this->{_dim}{R};

    $image->arc(
      $this->{_coords}{xc3},
      $this->{_coords}{yc3},
      $this->{_dim}{D},
      $this->{_dim}{D},
      0, 360, $this->{_conf_color}{black}
    );

    $this->{_coords}{xt3} = $this->{_coords}{xc3};
    $this->{_coords}{yt3} = $this->{_coords}{yc3} + ( $this->{_dim}{R} / 2 );

    $this->{_coords}{xt13} = $this->{_coords}{xc1} - ( $this->{_dim}{D} / 6 );
    $this->{_coords}{yt13} = $this->{_coords}{yc3} - ( $this->{_dim}{R} / 2 );

    $this->{_coords}{xt23} = $this->{_coords}{xc2};
    $this->{_coords}{yt23} = $this->{_coords}{yc3} - ( $this->{_dim}{R} / 3 );

    $this->{_coords}{xt123} = $this->{_coords}{xt3};
    $this->{_coords}{yt123} = $this->{_coords}{yc3} - 2 * ( $this->{_dim}{R} / 3 );

    if ( $this->{_colors}->[2] ) {
      $this->{_conf_color}{color3} = $image->colorAllocateAlpha( @{ $this->{_colors}->[2] } );
      my $ref_color13 = $this->_moy_color( $this->{_colors}->[0], $this->{_colors}->[2] );
      my $ref_color23 = $this->_moy_color( $this->{_colors}->[1], $this->{_colors}->[2] );
      my $ref_color123
        = $this->_moy_color( $this->{_colors}->[0], $this->{_colors}->[1], $this->{_colors}->[2] );
      $this->{_conf_color}{color13}  = $image->colorAllocateAlpha( @{$ref_color13} );
      $this->{_conf_color}{color23}  = $image->colorAllocateAlpha( @{$ref_color23} );
      $this->{_conf_color}{color123} = $image->colorAllocateAlpha( @{$ref_color123} );

      $image->fill( $this->{_coords}{xt3},   $this->{_coords}{yt3},   $this->{_conf_color}{color3} );
      $image->fill( $this->{_coords}{xt13},  $this->{_coords}{yt13},  $this->{_conf_color}{color13} );
      $image->fill( $this->{_coords}{xt23},  $this->{_coords}{yt23},  $this->{_conf_color}{color23} );
      $image->fill( $this->{_coords}{xt123}, $this->{_coords}{yt123}, $this->{_conf_color}{color123} );
      push( @{ $this->{_colors_regions} }, $this->{_colors}->[2], $ref_color13, $ref_color23, $ref_color123 );
    }

    $image->string( gdMediumBoldFont,
      $this->{_coords}{xt3},
      $this->{_coords}{yt3},
      $data3, $this->{_conf_color}{black}
    );
    $image->string( gdMediumBoldFont,
      $this->{_coords}{xt13},
      $this->{_coords}{yt13},
      $data13, $this->{_conf_color}{black}
    );
    $image->string( gdMediumBoldFont,
      $this->{_coords}{xt23},
      $this->{_coords}{yt23},
      $data23, $this->{_conf_color}{black}
    );
    $image->string( gdMediumBoldFont,
      $this->{_coords}{xt123},
      $this->{_coords}{yt123},
      $data123, $this->{_conf_color}{black}
    );

    $this->{_dim}{Hc} = $this->{_dim}{D} + $this->{_dim}{R};
    push( @{ $this->{_regions} },     $data3,  $data13,  $data23,  $data123 );
    push( @{ $this->{_listregions} }, \@list3, \@list13, \@list23, \@list123 );
  }

  return 1;
}

sub get_list_regions {
  my $this = shift;

  return @{ $this->{_listregions} } if ( $this->{_listregions} );
}

sub get_regions {
  my $this = shift;

  return @{ $this->{_regions} } if ( $this->{_regions} );
}

sub get_colors_regions {
  my $this = shift;

  if ( @{ $this->{_regions} } == 3 or @{ $this->{_regions} } == 7 ) {
    return @{ $this->{_colors_regions} };

  }
  else {
    croak("No data to plot");
  }
  return;
}

sub _moy_color {
  my ( $this, @couleurs ) = @_;
  my ( $R, $G, $B, $A ) = ( 0, 0, 0 );
  foreach my $ref_couleur (@couleurs) {
    $R += $ref_couleur->[0];
    $G += $ref_couleur->[1];
    $B += $ref_couleur->[2];
    $A += $ref_couleur->[3];
  }
  my $total = scalar(@couleurs);

  my @moy_couleur = ( int( $R / $total ), int( $G / $total ), int( $B / $total ), int( $A / $total ) );
  return \@moy_couleur;
}

sub plot_histogram {
  my $this = shift;

  # Get data regions
  my @regions = $this->get_regions();
  my ( @data, @names );
  if ( scalar @regions == 3 ) {
    @data = (
      [ "Region 1",  "Region 2",  "Region 1/2", ],
      [ $regions[0], undef,       undef, ],
      [ undef,       $regions[1], undef, ],
      [ undef,       undef,       $regions[2], ],
      [ undef,       undef,       undef, ],
      [ undef,       undef,       undef, ],
      [ undef,       undef,       undef, ],
      [ undef,       undef,       undef, ],
    );
  }
  elsif ( scalar @regions == 7 ) {
    @data = (
      [ "Region 1",  "Region 2",  "Region 1/2", "Region 3",  "Region 1/3", "Region 2/3", "Region 1/2/3" ],
      [ $regions[0], undef,       undef,        undef,       undef,        undef,        undef, ],
      [ undef,       $regions[1], undef,        undef,       undef,        undef,        undef, ],
      [ undef,       undef,       $regions[2],  undef,       undef,        undef,        undef, ],
      [ undef,       undef,       undef,        $regions[3], undef,        undef,        undef, ],
      [ undef,       undef,       undef,        undef,       $regions[4],  undef,        undef, ],
      [ undef,       undef,       undef,        undef,       undef,        $regions[5],  undef, ],
      [ undef,       undef,       undef,        undef,       undef,        undef,        $regions[6], ],
    );

  }
  else {
    croak("No data to plot an histogram");
    return;
  }

  my $graph = GD::Graph::bars->new( $this->{_width}, $this->{_height} );

  if ( $this->{_circles}{number} == 2 and $this->{_legends}{number} == 2 ) {
    @names
      = ( $this->{_legend}->[0], $this->{_legend}->[1], $this->{_legend}->[0] . '/' . $this->{_legend}->[1],
      );
    $graph->set_legend(@names);
  }
  elsif ( $this->{_circles}{number} == 3 and $this->{_legends}{number} == 3 ) {
    @names = (
      $this->{_legend}->[0],
      $this->{_legend}->[1],
      $this->{_legend}->[0] . '/' . $this->{_legend}->[1],
      $this->{_legend}->[2],
      $this->{_legend}->[0] . '/' . $this->{_legend}->[2],
      $this->{_legend}->[1] . '/' . $this->{_legend}->[2],
      $this->{_legend}->[0] . '/' . $this->{_legend}->[1] . '/' . $this->{_legend}->[2]
    );
    $graph->set_legend(@names);
  }
  elsif ( $this->{_circles}{number} > 0
    and $this->{_legends}{number} > 0
    and $this->{_circles}{number} != $this->{_legends}{number} )
  {
    carp("You have to set $this->{_circles}{number} legends if you want to see a legend");
  }

  $graph->set(
    cumulate      => 'true',
    box_axis      => 0,
    x_ticks       => 0,
    x_plot_values => 0,
  ) or warn $graph->error;

  my @color_regions = map { GD::Graph::colour::rgb2hex( @{$_}[ 0 .. 2 ] ) } $this->get_colors_regions();
  $graph->set( dclrs => \@color_regions );
  my $gd = $graph->plot( \@data ) or croak $graph->error;

  return $gd;
}

__END__

=head1 NAME

Venn::Chart - Create a Venn diagram using GD.

=head1 SYNOPSIS

  #!/usr/bin/perl
  use warnings;
  use Carp;
  use strict;
  
  use Venn::Chart;
  
  # Create the Venn::Chart constructor
  my $VennChart = new Venn::Chart( 400, 400 ) or die("error : $!");
  
  # Set a title and a legend for our chart
  $VennChart->set( -title => 'Venn diagram' );
  $VennChart->set_legends( 'Team 1', 'Team 2', 'Team 3' );
  
  # 3 lists for the Venn diagram
  my @Team1 = qw/abel edward momo albert jack julien chris/;
  my @Team2 = qw/edward isabel antonio delta albert kevin jake/;
  my @Team3 = qw/gerald jake kevin lucia john edward/;
  
  # Create a diagram with gd object
  my $gd_venn = $VennChart->plot( \@Team1, \@Team2, \@Team3 );
  
  # Create a Venn diagram image in png, gif and jpeg format
  open( my $fh_venn, '>', "VennChart.png" );
  binmode $fh_venn;
  print {$fh_venn} $gd_venn->png;
  close($fh_venn);
  
  # Create an histogram image of Venn diagram (png, gif and jpeg format)
  my $gd_histogram = $VennChart->plot_histogram;
  open( my $fh_histo, '>', "VennHistogram.png" );
  binmode $fh_histo;
  print {$fh_histo} $gd_histogram->png;
  close($fh_histo);
  
  # Get data list for each intersection or unique region between the 3 lists
  my @ref_lists = $VennChart->get_list_regions();
  my $list_number = 1;
  foreach my $ref_region ( @ref_lists ) {
    print "List $list_number : @{ $ref_region }\n";
    $list_number++;
  }

=head1 DESCRIPTION

Venn::Chart create a Venn diagram image using L<GD> module with 2 or 3 data lists. A title and a legend can be added in the chart. 
It is possible to create an histogram chart with the different data regions of Venn diagram using L<GD::Graph> module.

=head1 CONSTRUCTOR/METHODS

=head2 new

This constructor allows you to create a new Venn::Chart object.

B<$VennChart = new Venn::Chart($width, $height)>

The new() method is the main constructor for the Venn::Chart module. It creates a new blank image of the specified width and height.

  # Create Venn::Chart constructor
  my $VennChart = new Venn::Chart( 400, 400 );

The default width and height size are 500 pixels.

=head2 set

Set the image title and colors of the diagrams.

B<$VennChart-E<gt>set( -attrib =E<gt> value, ... )>

=over 4

=item B<-title> =E<gt> I<string>

Specifies the title.

  -title => 'Venn diagram',

=back

=over 4

=item B<-colors> =E<gt> I<array reference>

Specifies the RGBA colors of the 2 or 3 lists. This allocates a color with the specified red, green, and blue components, plus the specified alpha channel for each circle. 
The alpha value may range from 0 (opaque) to 127 (transparent). The alphaBlending function changes the way this alpha channel affects the resulting image.  

    -colors => [ [ 98, 66, 238, 0 ], [ 98, 211, 124, 0 ], [ 110, 205, 225, 0 ] ],

Default : B<[ [ 189, 66, 238, 0 ], [ 255, 133, 0, 0 ], [ 0, 107, 44, 0 ] ]>

=back

  $VennChart->set( 
    -title  => 'Venn diagram',
    -colors => [ [ 98, 66, 238, 0 ], [ 98, 211, 124, 0 ], [ 110, 205, 225, 0 ] ],
  );

=head2 set_legends

Set the image legends. This method set a legend which represents the title of each 2 or 3 diagrams (circles).

B<$VennChart-E<gt>set_legends( I<legend1, legend2, legend3> )>

  # Set title and a legend for our chart
  $VennChart->set_legends('Diagram1', 'Diagram2', 'Diagram3');


=head2 plot

Plots the chart, and returns the GD::Image object.

B<$VennChart-E<gt>plot( I<array reference list> )>

  my $gd = $VennChart->plot(\@list1, \@list2, \@list3);

To create your image, do whatever your current version of GD allows you to do to save the file. For example: 

  open( my $fh_image, '>', 'venn.png') or die("Error : $!");
  binmode $fh_image;
  print {$fh_image} $gd->png;
  close($fh_image);


=head2 get_list_regions

Get a list of array reference which contains data for each intersection or unique region between the 2 or 3 lists.

B<$VennChart-E<gt>get_list_regions()>

=over 4

=item B<Case : 2 lists>

  my $gd_venn   = $VennChart->plot( \@Team1, \@Team2 );
  my @ref_lists = $VennChart->get_list_regions();

@ref_lists will contain 3 array references.
  
  @{ $ref_lists[0] } => unique elements of @Team1 between @Team1 and @Team2    
  @{ $ref_lists[1] } => unique elements of @Team2 between @Team1 and @Team2
  @{ $ref_lists[2] } => intersection elements between @Team1 and @Team2   

=back

=over 4

=item B<Case : 3 lists>

  my $gd_venn   = $VennChart->plot( \@Team1, \@Team2, \@Team3 );
  my @ref_lists = $VennChart->get_list_regions();

@ref_lists will contain 7 array references.
  
  @{ $ref_lists[0] } => unique elements of @Team1 between @Team1, @Team2 and @Team3    
  @{ $ref_lists[1] } => unique elements of @Team2 between @Team1, @Team2 and @Team3  
  @{ $ref_lists[2] } => intersection elements between @Team1 and @Team2   
  @{ $ref_lists[3] } => unique elements of @Team3 between @Team1, @Team2 and @Team3  
  @{ $ref_lists[4] } => intersection elements between @Team3 and @Team1  
  @{ $ref_lists[5] } => intersection elements between @Team3 and @Team2  
  @{ $ref_lists[6] } => intersection elements between @Team1, @Team2 and @Team3

=back

Example :

  my @Team1 = qw/abel edward momo albert jack julien chris/;
  my @Team2 = qw/edward isabel antonio delta albert kevin jake/;
  my @Team3 = qw/gerald jake kevin lucia john edward/;
    
  my $gd_venn = $VennChart->plot( \@Team1, \@Team2, \@Team3 );
  my @lists   = $VennChart->get_list_regions();

  Result of @lists
  [ 'jack', 'momo', 'chris', 'abel', 'julien' ], # Unique of @Team1
  [ 'delta', 'isabel', 'antonio' ],              # Unique of @Team2
  [ 'albert' ],                                  # Intersection between @Team1 and @Team2
  [ 'john', 'gerald', 'lucia' ],                 # Unique of @Team3
  [],                                            # Intersection between @Team3 and @Team1
  [ 'jake', 'kevin' ],                           # Intersection between @Team3 and @Team2
  [ 'edward' ]                                   # Intersection between @Team1, @Team2 and @Team3


=head2 get_regions

Get an array displaying the object number of each region of the Venn diagram.

B<$VennChart-E<gt>get_regions()>

  my $gd_venn = $VennChart->plot( \@Team1, \@Team2, \@Team3 );
  my @regions = $VennChart->get_regions;

  @regions contains 5, 3, 1, 3, 0, 2, 1

=head2 get_colors_regions

Get an array contains the colors (in an array reference) used for each region in Venn diagram.

B<$VennChart-E<gt>get_colors_regions()>

  my @colors_regions = $VennChart->get_colors_regions;

  @colors_regions = (
    [R, G, B, A], [R, G, B, A], [R, G, B, A],
    [R, G, B, A], [R, G, B, A], [R, G, B, A],
    [R, G, B, A]
  ); 


  @{ $colors_regions[0] } => color of @{ $ref_lists[0] }    
  @{ $colors_regions[1] } => color of @{ $ref_lists[1] }
  @{ $colors_regions[2] } => color of @{ $ref_lists[2] }   
  @{ $colors_regions[3] } => color of @{ $ref_lists[3] }  
  @{ $colors_regions[4] } => color of @{ $ref_lists[4] }
  @{ $colors_regions[5] } => color of @{ $ref_lists[5] }
  @{ $colors_regions[6] } => color of @{ $ref_lists[6] }

=head2 plot_histogram

Plots an histogram displaying each region of the Venn diagram which returns the GD::Image object.

B<$VennChart-E<gt>plot_histogram>

To create the histogram, the Venn diagram have to be already created. 

  # Create histogram of Venn diagram image in png, gif and jpeg format
  my $gd_histogram = $VennChart->plot_histogram;
  
  open( my $fh_histo, '>', 'VennHistogram.png') or die("Error : $!");
  binmode $fh_histo;
  print {$fh_histo} $gd_histogram->png;
  close($fh_histo);

If you want to create and design the histogram yourself, use L<GD::Graph> module and play with data obtained with L</"get_regions"> methods.

=head1 AUTHOR

Djibril Ousmanou, C<< <djibel at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-venn-chart at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Venn-Chart>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SEE ALSO

See L<GD>, L<GD::Graph>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Venn::Chart


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Venn-Chart>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Venn-Chart>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Venn-Chart>

=item * Search CPAN

L<http://search.cpan.org/dist/Venn-Chart/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Djibril Ousmanou.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Venn::Chart
