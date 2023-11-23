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
    $exif_tool->SetNewValue($key => $input_info->{$key});
}

# Delete all files in output directory first
my $dir = 'output';
opendir(my $dh, $dir) or die "Cannot open $dir: $!";
while (my $file = readdir($dh)) {
    next if ($file =~ m/^\./);
    unlink "$dir/$file";
}

for my $x (0, int($width - $new_width)) {
    for my $y (0, int($height - $new_height)) {
        print "Cropping $x, $y...\n";
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

        # Write the metadata to the temporary file taking into account our new set values
        $exif_tool->WriteInfo($temp_file, "output/${x}_${y}.jpg");

        # Delete the temporary file
        unlink $temp_file;
    }
}
print "Images cropped successfully!\n";