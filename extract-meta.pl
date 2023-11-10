#!/usr/bin/perl
#
use strict;
use Image::ExifTool;
use Geo::Coordinates::DecimalDegrees;

my $exif_t = Image::ExifTool->new;

my $dir = $ARGV[0];
#print "$dir\n";
my $dh;
opendir($dh, $dir);
my @files = readdir($dh);
foreach my $file (@files) {
    if($file =~ /\.(jpg|JPG|jpeg)$/) {
        #print "$dir/$file\n\n";
        my $info = $exif_t->ImageInfo("$dir/$file");

        ## 47 deg 12' 6.39" N	
        my @lat = $$info{'GPSLatitude'} =~ /^([0-9]+)\s+deg\s+([0-9]+)\'\s+([0-9]+\.[0-9]+)\"\s+[NSEW]$/;
        my $lat = dms2decimal($lat[0], $lat[1], $lat[2]);

        ## 33 deg 8' 20.81" E
        my @lon = $$info{'GPSLongitude'} =~ /^([0-9]+)\s+deg\s+([0-9]+)\'\s+([0-9]+\.[0-9]+)\"\s+[NSEW]$/;
        my $lon = dms2decimal($lon[0], $lon[1], $lon[2]);
        print "$file\t$lat\t$lon\n";

        ## use this to see all metadata
        #foreach (sort keys %$info) {
        #print "$_ => $$info{$_}\n";
        #}
        #print "\n";
    }
}
closedir($dh);
