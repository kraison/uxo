#!/usr/bin/perl
#
# This Will Load Assessment Data From A JSON File ( Assessment.json )
# The Result Is A KML File ( FlightPath.kml )
# Taking the prefered flight path location and adding it to the KML file
#

use strict;
use warnings;
use XML::LibXML;
use Data::Dumper;
use HTML::Template;
use List::Util qw(min);

# Constants
use constant {
    LeftToRight => 0, # Lat Low To High
    RightToLeft => 1, # Lat High To Low
    TopToBottom => 2, # Lon High To Low
    BottomToTop => 3  # Lon Low To High
};

# Direction To Start Path ( User Input )
my $pathStartDirection = RightToLeft;

# Varibles
# Choose a starting coordinate
my $start_coord;
# Final string to be used in the KML file
my @finalString;

# Read the KML file
my $kml_file = '..\assessment\output\AssessmentResult.kml';
my $parser = XML::LibXML->new();
my $doc = $parser->parse_file($kml_file);

# Define namespace for KML
my $ns = 'http://www.opengis.net/kml/2.2';

# Find all coordinates within the KML file
my @coordinates;

foreach my $placemark ($doc->findnodes("//*[local-name()='Placemark']")) {
    my $point_node = $placemark->findnodes("./*[local-name()='Point']/*[local-name()='coordinates']")->get_node(1);
    next unless $point_node;

    my $coordinates_node = $point_node->textContent;

    # Split the coordinates string and store them in an array
    my @coords = map { [split /,\s*/, $_] } split /\n/, $coordinates_node;
    foreach my $coord (@coords) {
        my ($lon, $lat) = @$coord;
        if (defined $lon && defined $lat) {
            # push @coordinates, [$lon, $lat];
            push(@coordinates, { LAT => $lat, LON => $lon });
        }
    }
}

# Function to calculate distance between two points
sub distance {
    my ($x1, $y1, $x2, $y2) = @_;
    return sqrt(($x2 - $x1) ** 2 + ($y2 - $y1) ** 2);
}

# Function to find the nearest neighbor
sub nearest_neighbor {
    my ($coords, $start) = @_;
    my @remaining_coords = @{$coords};
    my @path = ($start);
    my $current_point = $start;

    while (@remaining_coords) {
        my $min_dist = -1;
        my $nearest_point;

        foreach my $point (@remaining_coords) {
            my $dist = distance($current_point->{LAT}, $current_point->{LON}, $point->{LAT}, $point->{LON});
            if ($min_dist == -1 || $dist < $min_dist) {
                $min_dist = $dist;
                $nearest_point = $point;
            }
        }

        push @path, $nearest_point;
        @remaining_coords = grep { $_ ne $nearest_point } @remaining_coords;
        $current_point = $nearest_point;
    }

    return \@path;
}

# Switch Statement To Sort Places By Direction
if ($pathStartDirection == LeftToRight) {
    # Sort Places By Latitude ( Lat Low To High )
    @coordinates = sort { $a->{LAT} <=> $b->{LAT} } @coordinates;
} elsif ($pathStartDirection == RightToLeft) {
    # Sort Places By Latitude ( Lat High To Low )
    @coordinates = sort { $b->{LAT} <=> $a->{LAT} } @coordinates;
} elsif ($pathStartDirection == TopToBottom) {
    # Sort Places By Longitude ( Lon High To Low )
    @coordinates = sort { $a->{LON} <=> $b->{LON} } @coordinates;
} elsif ($pathStartDirection == BottomToTop) {
    # Sort Places By Longitude ( Lon Low To High )
    @coordinates = sort { $b->{LON} <=> $a->{LON} } @coordinates;
}

# Choose a starting coordinate
$start_coord = { LON => $coordinates[0]->{LON}, LAT => $coordinates[0]->{LAT} };
#print "Start Coordinate: $start_coord[0]->{LAT}, $start_coord[0]->{LON}\n";

# Get the first and last coordinates for start and end points
my @startPin = $coordinates[0];
# Make a KML happy string
my @startPinString = "$startPin[0]->{LON},$startPin[0]->{LAT},0";

# Find the path using nearest neighbor algorithm
my $path = nearest_neighbor(\@coordinates, $start_coord);

#print Dumper $path;

my @endPin = @$path[scalar @$path - 1];
my @endPinString = "$endPin[0]->{LON},$endPin[0]->{LAT},0";

# Build The Cords Into A String That The KML Likes
foreach my $coord (@$path) {
    # Build A String
    my $line = "$coord->{LON},$coord->{LAT},0 ";
    # Append Line to String
    push(@finalString, $line);
};

# KML template path
my $template_path = HTML::Template->new(filename => 'kml_path.tmpl');

# Add The Final String To The Template
$template_path->param(PATH => "@finalString");
# Add The Start And End Pins To The Template
$template_path->param(STARTPIN => "@startPinString");
$template_path->param(ENDPIN => "@endPinString");
# Open or create output KML file
open(my $gh, '>', "output/FlightPath.kml") or die "Cannot open file: $!";
print $gh $template_path->output;
# Close output file
close($gh);

