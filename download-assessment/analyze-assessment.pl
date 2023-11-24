#!/usr/bin/perl
#
# This Will Load Assessment Data From A JSON File ( Assessment.json )
# The Result Is Downloading All Images That Have Been Tagged As Hazards
# Taking Each "Orange" Hazard And Downloading the Image
#

use strict;
use HTML::Template;
use Data::Dumper;
use JSON;
use LWP::UserAgent;
use MIME::Base64;
use HTML::TreeBuilder;
use Image::ExifTool;

# User token
my $access_token = "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJsN080Wm5ZN0lBSjdRcDVyWk1ta0hRc2o0VUdyVlQ4bmRaOW9xdnhMNmtNIn0.eyJleHAiOjE3MDA5MTE5OTcsImlhdCI6MTcwMDgyNTYxOSwiYXV0aF90aW1lIjoxNzAwODI1NTk3LCJqdGkiOiJhMDU3MzYzNi1mYTVkLTQ2YjQtOGRlMi1mZWZkMzFkMWFlM2MiLCJpc3MiOiJodHRwczovL2tleWNsb2FrLnNhZmVwcm8uYWkvcmVhbG1zL3NhZmUtcHJvLWFpIiwiYXVkIjoiYWNjb3VudCIsInN1YiI6IjdhYTI5ZWZjLTZmNDktNDNmYi1iMjEyLTJlNjEyY2M3YjViYiIsInR5cCI6IkJlYXJlciIsImF6cCI6ImRlbWluaW5nLWFwcCIsIm5vbmNlIjoiMWYxOGY0ZjEtZjc3YS00ZWQ3LThlZjQtYzI0ODEzZjhlMzYzIiwic2Vzc2lvbl9zdGF0ZSI6IjdiZDZlZGMyLTUzZjYtNDYxNi1hZWNlLWNkNjFiOTU0ZmUzMiIsImFjciI6IjEiLCJhbGxvd2VkLW9yaWdpbnMiOlsiaHR0cHM6Ly9zYWZlcHJvLmFpIl0sInJlYWxtX2FjY2VzcyI6eyJyb2xlcyI6WyJkZWZhdWx0LXJvbGVzLXNhZmUtcHJvLWFpIiwib2ZmbGluZV9hY2Nlc3MiLCJ1bWFfYXV0aG9yaXphdGlvbiJdfSwicmVzb3VyY2VfYWNjZXNzIjp7ImFjY291bnQiOnsicm9sZXMiOlsibWFuYWdlLWFjY291bnQiLCJtYW5hZ2UtYWNjb3VudC1saW5rcyIsInZpZXctcHJvZmlsZSJdfX0sInNjb3BlIjoib3BlbmlkIGVtYWlsIHByb2ZpbGUiLCJzaWQiOiI3YmQ2ZWRjMi01M2Y2LTQ2MTYtYWVjZS1jZDYxYjk1NGZlMzIiLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwibmFtZSI6IkJyeW9uIE1hcGVzIiwicHJlZmVycmVkX3VzZXJuYW1lIjoiYnJ5b25tYXBlc0BnbWFpbC5jb20iLCJnaXZlbl9uYW1lIjoiQnJ5b24iLCJmYW1pbHlfbmFtZSI6Ik1hcGVzIiwiZW1haWwiOiJicnlvbm1hcGVzQGdtYWlsLmNvbSJ9.K7gk2I9-oEyQ96njvU3ieJcwk5uDLe1FZE5NOWnY-fVOw-8l7wrU4lLaPDpsFjBcRqicLoJn3wAgSNdLvxFcvipc2eLEklixbI_WAqBYYri33KeKI2crs90_l-goGaQ2d07XL-RyHD5xcCSkHcwGDBjB5Sw-I8FwpiPdUQVfHx4D-Y1B283w6LVAobNIJsdfVKGtVgd6bNKJNgr8zd7xXO4-YuECRFUS50pajO97rU8hFV9cK4ShwMfYmdHRTRRpGRS5esBl0FR8ic1b7LPSD5jDawPfiQBm9WTOTIB7TfQAQPTKLJxnXB5q6b2C5rEGj61ME3iQkBQ7IeSDvGO4PA";

my(@Hazards);

# Load JSON From Assessment.json
my $json_text = do {
    open(my $json_fh, "<:encoding(UTF-8)", 'Assessment.json')
        or die("Can't open \$filename\": $!\n");
    local $/;
    <$json_fh>
};

#
# Create an ExifTool object to handle metadata
my $exif_tool = Image::ExifTool->new;

# Decode The JSON That We Get From Spotlight
my $data = decode_json($json_text);

# Loop Through The JSON To Check For Hazards
foreach my $t_place (@$data) {
    # If The Color Is Orange Then It Is Possibly A Hazard
    if($t_place->{'properties'}->{'color'} eq "orange"){
        # URL
        my $url = $t_place->{'properties'}->{'image_url'};
        # Coords
        my $coords = $t_place->{'geometry'}->{'coordinates'};
        # Replace The HTML Safe Characters
        $url =~ s/\u0026/&/;
        # Swap in the valid access token
        $url =~ s/access_token=.*/access_token=${access_token}/;
        # Add The Information To Our Hazards Array
        push @Hazards, { URL => $url, COORDS => $coords };
    }
}

# Index
my $index = 1;
# Variable to store the total size of the file
my $total_size = 0;
# Total number of files to download
my $total_files = scalar @Hazards;
# Loop Through The Hazards Array And Download The Images
foreach my $hazard (@Hazards) {
    # Get The URL
    my $url = $hazard->{URL};
    # Coords
    my @coords = $hazard->{COORDS};
    # Get The File Name
    my $filename = $index;
    # Output temp
    my $output_temp = "output/$index-temp.jpg";
    # Output File Name
    my $output_file = "output/$index.jpg";

    my $ua = LWP::UserAgent->new;
    $ua->timeout(120); # Set a timeout value (in seconds) for the request

    my $response = $ua->get($url);

    if ($response->is_success) {
        my $html_content = $response->content;
        my $tree = HTML::TreeBuilder->new_from_content($html_content);
        my $img_tag = $tree->look_down(_tag => 'img');

        if ($img_tag) {
            my $image_url = $img_tag->attr('src');
            if ($image_url) {
                my $image_response = $ua->get($image_url);

                if ($image_response->is_success) {
                    open my $fh, '>', $output_temp or die "Cannot open file: $!";
                    binmode $fh;
                    print $fh $image_response->content;
                    close $fh;

                    print "Image $index/$total_files downloaded successfully to $output_temp\n";
                } else {
                    print "Failed to download image: " . $image_response->status_line . "\n";
                }
            } else {
                print "No image URL found.\n";
            }
        } else {
            print "No image tag found.\n";
        }

        $tree->delete;
    } else {
        print "Failed to fetch URL: " . $response->status_line . "\n";
    }
    # Do metadata stuffs
    my $input_info = $exif_tool->ImageInfo($output_temp);
    my $lat = $coords[0][0];
    my $lon = $coords[0][1];
    $exif_tool->SetNewValue("GPSLatitude" => $lat, Protected => 1, Replace => 1);
    $exif_tool->SetNewValue("GPSLongitude" => $lon, Protected => 1, Replace => 1);
    $exif_tool->WriteInfo($output_temp, $output_file);

    # Delete The Temp File
    unlink $output_temp;

    # Increment Index
    $index++;
}
print "Done!\n";
die;


# I need To Orginize Everything Under This..



# Code For Generating A Litchi Mission To Hazard Points
# ActionType
use constant {
    Nothing => -1,          # Param: Default
    Stay => 0,              # Param: time(ms)
    TakePicture => 1,       # Param: Default    
    StartRecording => 2,    # Param: Default
    StopRecording => 3,     # Param: Default
    RotateDrone => 4,       # Param: number(degrees) ( Unknown )
    TiltCamera => 5         # Param: number(degrees) (-90 ~ +90 )
};
# ActionParam
use constant {
    Default => 0
};

#
#

#my $template_path = HTML::Template->new(filename => 'kml_path.tmpl');
#
#
#
#my(@placesWithCoords);
# Split Places Element Into Latitude And Longitude
#foreach my $place (@Hazards) {
#    my @coords = split(/, /, $place->{COORDS});
#    push(@placesWithCoords, { LAT => $coords[0], LON => $coords[1] });
#}
# Direction To Start Path ( User Input )
#my $pathStartDirection = TopToBottom;

# Switch Statement To Sort Places By Direction
#if ($pathStartDirection == LeftToRight) {
    # Sort Places By Latitude ( Lat Low To High )
#    @placesWithCoords = sort { $a->{LAT} <=> $b->{LAT} } @placesWithCoords;
#} elsif ($pathStartDirection == RightToLeft) {
    # Sort Places By Latitude ( Lat High To Low )
#    @placesWithCoords = sort { $b->{LAT} <=> $a->{LAT} } @placesWithCoords;
#} elsif ($pathStartDirection == TopToBottom) {
    # Sort Places By Longitude ( Lon High To Low )
#    @placesWithCoords = sort { $b->{LON} <=> $a->{LON} } @placesWithCoords;
#} elsif ($pathStartDirection == BottomToTop) {
    # Sort Places By Longitude ( Lon Low To High )
#    @placesWithCoords = sort { $a->{LON} <=> $b->{LON} } @placesWithCoords;
#}

# Create CSV File
#open(my $fhh, '>', "Litchi.csv") or die "Cannot open file: $!";
# Write CSV Headers
#print $fhh "latitude,longitude,altitude(m),heading(deg),curvesize(m),rotationdir,gimbalmode,gimbalpitchangle,actiontype1,actionparam1,actiontype2,actionparam2,actiontype3,actionparam3,actiontype4,actionparam4,actiontype5,actionparam5,actiontype6,actionparam6,actiontype7,actionparam7,actiontype8,actionparam8,actiontype9,actionparam9,actiontype10,actionparam10,actiontype11,actionparam11,actiontype12,actionparam12,actiontype13,actionparam13,actiontype14,actionparam14,actiontype15,actionparam15,altitudemode,speed(m/s),poi_latitude,poi_longitude,poi_altitude(m),poi_altitudemode,photo_timeinterval,photo_distinterval\n";
#close $fhh;

#my %usesConstant = (ActionType => Nothing);
#print $usesConstant{ActionType};

# Build The Cords Into A String That The KML Likes
#my @finalString;
#foreach my $place (@placesWithCoords) {
    # Build A String
#    my $line = "$place->{LAT},$place->{LON},0 ";
    # Append Line to String
#    push(@finalString, $line);
#};

# Get The first And Last Cords
#my @startPin = $placesWithCoords[0];
#my @endPin = $placesWithCoords[scalar @placesWithCoords - 1];

#my @startPinString = "$startPin[0]->{LAT},$startPin[0]->{LON},0";
#my @endPinString = "$endPin[0]->{LAT},$endPin[0]->{LON},0";

# Add The Final String To The Template
#$template_path->param(PATH => "@finalString");
# Add The Start And End Pins To The Template
#$template_path->param(STARTPIN => "@startPinString");
#$template_path->param(ENDPIN => "@endPinString");
# Open or create output KML file
#open(my $gh, '>', "OutputPath.kml") or die "Cannot open file: $!";
#print $gh $template_path->output;
# Close output file
#close($gh);