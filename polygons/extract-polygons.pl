#!/usr/bin/perl
#
# This Will Load a directory of Dronelink Mission Files ( ARGV[0] )
# The Result Is A KML File ( mission-polygon.kml )
# Extracting the bounding boxes from the mission files
#

use strict;
use warnings;
use XML::LibXML;
use Data::Dumper;
use HTML::Template;
use List::Util qw(min);
use List::MoreUtils qw( minmax );

my $template = HTML::Template->new(filename => 'polygons.tmpl');
my @missions;

# Read the KML files
my $mission_dir = $ARGV[0];
my $dh;
opendir($dh, $mission_dir);
my @files = readdir($dh);
closedir($dh);

foreach my $kml_file (@files) {
    next unless $kml_file =~ /\.kml$/;

    my %mission;
    my $parser = XML::LibXML->new();
    my $doc = $parser->parse_file("$mission_dir/$kml_file");
    
    # Find all coordinates within the KML file and extract MinX, MinY, MaxX and MaxY
    my @coordinates;
    my(@latitudes,@longitudes);
    
    foreach my $placemark ($doc->findnodes("//*[local-name()='Placemark']")) {
        my $desc = ($placemark->findnodes("./*[local-name()='description']")->get_node(1));
        next unless $desc;
        if($desc->textContent eq 'Single Photo') {
            my $point_node = $placemark->findnodes("./*[local-name()='Point']/*[local-name()='coordinates']")->get_node(1);
            next unless $point_node;
    
            my $coordinates_node = $point_node->textContent;
    
            # Split the coordinates string and store them in an array
            my @coords = map { [split /,\s*/, $_] } split /\n/, $coordinates_node;
            foreach my $coord (@coords) {
                my ($lon, $lat) = @$coord;
                if (defined $lon && defined $lat) {
                    push(@latitudes,$lat);
                    push(@longitudes,$lon);
    
                    push(@coordinates, { LAT => $lat, LON => $lon });
                }
            }
        }
    }
    
    ## Simple bounding box using synthetic coordinates
    my($min_lat, $max_lat) = minmax(@latitudes);
    my($min_lon, $max_lon) = minmax(@longitudes);
    
    $mission{'MINLAT'} = $min_lat;
    $mission{'MAXLAT'} = $max_lat;
    $mission{'MINLON'} = $min_lon;
    $mission{'MAXLON'} = $max_lon;
    
    ## Find the vertexes of the polygon;  we assume 4 for now; that's not a great assumption
    my @outside_coords;
    foreach my $c (@coordinates) {
        if($c->{'LAT'} == $min_lat or $c->{'LAT'} == $max_lat or $c->{'LON'} == $min_lon or $c->{'LON'} == $max_lon) {
            push(@outside_coords,$c);
        }
    }
    sub coord_sort {
        #if($a->{'LAT'} <= $b->{'LAT'} and $a->{'LON'} <= $b->{'LON'}) {
        if($a->{'LAT'} <= $b->{'LAT'}) {
            return(1);
        }
    }
    @outside_coords = sort coord_sort @outside_coords;
    $mission{'LAT1'} = $outside_coords[0]->{'LAT'};
    $mission{'LAT2'} = $outside_coords[1]->{'LAT'};
    $mission{'LAT3'} = $outside_coords[2]->{'LAT'};
    $mission{'LAT4'} = $outside_coords[3]->{'LAT'};
    $mission{'LON1'} = $outside_coords[0]->{'LON'};
    $mission{'LON2'} = $outside_coords[1]->{'LON'};
    $mission{'LON3'} = $outside_coords[2]->{'LON'};
    $mission{'LON4'} = $outside_coords[3]->{'LON'};

    push(@missions,\%mission);
}    

## Write the kml to STDOUT for now.
$template->param(MISSION => \@missions);
print $template->output;
    
exit(0);

