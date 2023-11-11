#!/usr/bin/perl
#
use strict;
use Image::ExifTool;
use Geo::Coordinates::DecimalDegrees;
use HTML::Template;

#my $drive_folder = "https://drive.google.com/drive/folders/1Q8JHxwhE6Jr9Uu1FOj_VMtTQFgFJ33cJ/";
my $url = "https://www.bluestarsunflower.org/uxo";
my $template = HTML::Template->new(filename => 'kml.tmpl');

my $exif_t = Image::ExifTool->new;

my $dir = $ARGV[0];
my $dh;
opendir($dh, $dir);
my @files = readdir($dh);
closedir($dh);

my(@places);
my $new_width = 350;
my $i = 0;
foreach my $file (@files) {
    if($file =~ /\.(jpg|JPG|jpeg)$/) {
        ++$i;
        #print "$dir/$file\n\n";
        my $info = $exif_t->ImageInfo("$dir/$file");

        my $height = $$info{'ImageHeight'};
        my $width = $$info{'ImageWidth'};
        my $new_height = $new_width * ($height / $width);

        ## 47 deg 12' 6.39" N	
        my @lat = $$info{'GPSLatitude'} =~ /^([0-9]+)\s+deg\s+([0-9]+)\'\s+([0-9]+\.[0-9]+)\"\s+[NSEW]$/;
        my $lat = dms2decimal($lat[0], $lat[1], $lat[2]);
        #my $lat = $$info{'GPSLatitude'};

        ## 33 deg 8' 20.81" E
        my @lon = $$info{'GPSLongitude'} =~ /^([0-9]+)\s+deg\s+([0-9]+)\'\s+([0-9]+\.[0-9]+)\"\s+[NSEW]$/;
        my $lon = dms2decimal($lon[0], $lon[1], $lon[2]);
        #my $lon = $$info{'GPSLongitude'};

        #print "$url/$file\t$lat\t$lon\n";
        my $desc = "Hazard $i";
        push(@places, { URL => "$url/$file", COORDS => "$lon, $lat", NAME => $desc, HEIGHT => $new_height, WIDTH => $new_width });


        ## use this to see all metadata
        #foreach (sort keys %$info) {
        #print STDERR "$_ => $$info{$_}\n";
        #}
        #print STDERR "\n";
    }
}
$template->param(POINT => \@places);
print $template->output;
