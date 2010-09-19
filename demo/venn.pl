#!/usr/bin/perl
#==================================================================
# Author    : Djibril Ousmanou
# Copyright : 2010
# Update    : 19/09/2010 20:32:59
# AIM       : Venn diagram example
#==================================================================
use warnings;
use Carp;
use strict;

use Venn::Chart;

# Create the Venn::Chart constructor
my $VennChart = new Venn::Chart( 400, 400 ) or die("error : $!");

# Set a title and a legend for our chart
$VennChart->set( -title => 'Venn Diagram' );
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

# Create an histogram image of Venn diagram (png, gif and jpeg format).
my $gd_histogram = $VennChart->plot_histogram;
open( my $fh_histo, '>', "VennHistogram.png" );
binmode $fh_histo;
print {$fh_histo} $gd_histogram->png;
close($fh_histo);