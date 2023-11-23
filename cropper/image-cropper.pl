#!/usr/bin/perl
#
# This Will Take A Single Image From Input And Crop It Into 4 Images
# The Result Is 4 Images In The Output Directory
# The GPS Data Is Copied From The Input Image To The Output Images
# So The Output Images Will Be Stacked In The Software ( I may try to spoof the GPS to fix this )
# Ultimatly This Doesn't Do Anything Useful Because I Think You Could Just Upload 2 Of The Same Images For The Same Result
# Unknown If Hazard Map Will Process This Correctly ( Unlikely As I can't Even Get It To Process Correct Data )
#
use strict;
use warnings;
use GD;
use Image::ExifTool;

# Spoof GPD Offset
my $gpsOffsetLat = 0.035; # Lat changes in greatter increments than lon ( keep this a bit smaller than lon )
my $gpsOffsetLon = 0.04; # Lon changes in smaller increments than lat

# Input image file name
my $input_image = 'input/input.jpg';

# Create GD image object
my $image = GD::Image->new($input_image) or die "Cannot open $input_image: $!";

# Get image dimensions
my ($width, $height) = $image->getBounds();

# New image dimensions will be 70% of the original image dimensions
my $new_width = $width * 0.7;
my $new_height = $height * 0.7;

# Calculate the crop points for the four separate images
my $crop_width = int($width * 0.3);
my $crop_height = int($height * 0.3);

# Create an ExifTool object to handle metadata
my $exif_tool = Image::ExifTool->new;

# Get The Make and Model of the camera used to take the image
my $input_info = $exif_tool->ImageInfo($input_image);

# Loop over all the metadata keys and prepare to copy them to the new images
for my $key (keys %$input_info) {
    #print "$key => $input_info->{$key}\n";
    #print "---- \n";
    #print "---- \n";
    # Skip the GPS data as we will be setting that manually
    next if ($key =~ m/^GPSLatitude|GPSLongitude|GPSPosition/);
    $exif_tool->SetNewValue($key => $input_info->{$key});
}

# Delete all files in output directory first
my $dir = 'output';
opendir(my $dh, $dir) or die "Cannot open $dir: $!";
while (my $file = readdir($dh)) {
    next if ($file =~ m/^\./);
    unlink "$dir/$file";
}

my $index = 0;
for my $x (0, int($width - $new_width)) {
    for my $y (0, int($height - $new_height)) {
        # All the new images will be 70% of the original image
        my $new_image = GD::Image->new($new_width, $new_height);
        # $image->copy($sourceImage,$dstX,$dstY,$srcX,$srcY,$width,$height)
        # $dstX,$dstY : We always want to stamp at 0,0 of the new image
        # $srcX,$srcY : The top left of the crop area being taken from the original image ( ( 0,0 ), ( 0, 30% ), ( 30%, 0 ), ( 30%, 30% )
        # $width,$height : The width and height of the crop area ( 70% )
        $new_image->copy($image, 0, 0, $x, $y, $new_width, $new_height);

        # Save the new image to a temporary file
        my $temp_file = "temp/crop_${x}_${y}_temp.jpg";
        open(my $out, '>', $temp_file) or die "Cannot open output file: $!";
        binmode $out;
        print $out $new_image->jpeg;
        close $out;

        # Handle GPS data
        for my $key (keys %$input_info) {
            # Up Down
            if ($key eq 'GPSLatitude') {
                if ($input_info->{$key} =~ /(\d+) deg (\d+)' (\d+\.\d+)\" (\w+)/) {
                    my $degrees = $1;
                    my $minutes = $2;
                    my $seconds = $3;
                    my $direction = $4;

                    # The first image will be the top left of the original image so move it up
                    if ($index == 0) {
                        $seconds += $gpsOffsetLat;
                    } elsif ($index == 1) {
                        # The second image will be the bottom left of the original image so move it down
                        $seconds -= $gpsOffsetLat;
                    } elsif ($index == 2) {
                        # The third image will be the top right of the original image so move it up
                        $seconds += $gpsOffsetLat;
                    } elsif ($index == 3) {
                        # The fourth image will be the bottom right of the original image so move it down
                        $seconds -= $gpsOffsetLat;
                    }

                    # Convert back to original format
                    my $edited = "$degrees deg $minutes' $seconds\" $direction";
                    
                    # Set the new value
                    $exif_tool->SetNewValue($key => $edited, Protected => 1, Replace => 1);
                }
                next;
            }
            # Left Right
            if ($key eq 'GPSLongitude') {
                if ($input_info->{$key} =~ /(\d+) deg (\d+)' (\d+\.\d+)\" (\w+)/) {
                    my $degrees = $1;
                    my $minutes = $2;
                    my $seconds = $3;
                    my $direction = $4;

                    # The first image will be the top left of the original image so move it left
                    if ($index == 0) {
                        $seconds -= $gpsOffsetLon;
                    } elsif ($index == 1) {
                        # The second image will be the bottom left of the original image so move it left
                        $seconds -= $gpsOffsetLon;
                    } elsif ($index == 2) {
                        # The third image will be the top right of the original image so move it right
                        $seconds += $gpsOffsetLon;
                    } elsif ($index == 3) {
                        # The fourth image will be the bottom right of the original image so move it right
                        $seconds += $gpsOffsetLon;
                    }

                    # Convert back to original format
                    my $edited = "$degrees deg $minutes' $seconds\" $direction";

                    # Set the new value
                    $exif_tool->SetNewValue($key => $edited, Protected => 1, Replace => 1);
                }
                next;
            }
            # Left Right
            if ($key eq 'GPSPosition') {
                if ($input_info->{$key} =~ /(\d+) deg (\d+)' (\d+\.\d+)\" (\w+), (\d+) deg (\d+)' (\d+\.\d+)\" (\w+)/) {
                my $lat_degrees = $1;
                my $lat_minutes = $2;
                my $lat_seconds = $3;
                my $lat_direction = $4;

                my $long_degrees = $5;
                my $long_minutes = $6;
                my $long_seconds = $7;
                my $long_direction = $8;

                # Mirror what we are doing above
                if ($index == 0) {
                    $lat_seconds += $gpsOffsetLat;
                    $long_seconds -= $gpsOffsetLon;
                } elsif ($index == 1) {
                    $lat_seconds -= $gpsOffsetLat;
                    $long_seconds -= $gpsOffsetLon;
                } elsif ($index == 2) {
                    $lat_seconds += $gpsOffsetLat;
                    $long_seconds += $gpsOffsetLon;
                } elsif ($index == 3) {
                    $lat_seconds -= $gpsOffsetLat;
                    $long_seconds += $gpsOffsetLon;
                }

                # Convert back to original format
                my $edited = "$lat_degrees deg $lat_minutes' $lat_seconds\" $lat_direction, $long_degrees deg $long_minutes' $long_seconds\" $long_direction";
                
                # Set the new value
                $exif_tool->SetNewValue($key => $edited, Protected => 1, Replace => 1);
                } else {
                    print "Format not recognized.\n";
                }
                next;
            }
        }
        #

        # Write the metadata to the temporary file taking into account our new set values
        $exif_tool->WriteInfo($temp_file, "output/${x}_${y}.jpg");

        # Delete the temporary file
        unlink $temp_file;

        $index += 1;
    }
}
print "Images cropped successfully!\n";