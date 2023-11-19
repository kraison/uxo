#!/usr/bin/perl
#
# This Will Load Assessment Data From A JSON File ( Assessment.json )
# The Result Is A KML File ( AssessmentResult.kml )
# Taking Each "Orange" Hazard And Adding A Point To The KML File
#

use strict;
use HTML::Template;
use Data::Dumper;
use JSON;

my(@places);

my $template = HTML::Template->new(filename => 'kml.tmpl');

# Load JSON From Assessment.json
my $json_text = do {
    open(my $json_fh, "<:encoding(UTF-8)", "Assessment.json")
        or die("Can't open \$filename\": $!\n");
    local $/;
    <$json_fh>
};

# Decode The JSON That We Get From Spotlight
my $data = decode_json($json_text);

# Loop Through The JSON To Check For Hazards
foreach my $t_place (@$data) {
    # If The Color Is Orange Then It Is Possibly A Hazard
    if($t_place->{'properties'}->{'color'} eq "orange"){
        # Coords
        my $coords = $t_place->{'geometry'}->{'coordinates'};
        # Latitude
        my $lat = @$coords[0];
        # Longitude
        my $lon = @$coords[1];
        # Add The Location To Our Places Array With Some Extra Data
        push @places, { URL => "www.google.com", COORDS => "$lon, $lat", NAME => $t_place->{'properties'}->{'index'}, HEIGHT => 100, WIDTH => 100 };
    }
}

# Open or create output KML file
open(my $ch, '>', "output/AssessmentResult.kml") or die "Cannot open file: $!";
# Assign Template Variable
$template->param(POINT => \@places);
# Print Template Output To File
print $ch $template->output;
# Close output file
close($ch);


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
# PathStartDirection
use constant {
    LeftToRight => 0, # Lat Low To High
    RightToLeft => 1, # Lat High To Low
    TopToBottom => 2, # Lon High To Low
    BottomToTop => 3  # Lon Low To High
};

#
#

my $template_path = HTML::Template->new(filename => 'kml_path.tmpl');
#
#
#
my(@placesWithCoords);
# Split Places Element Into Latitude And Longitude
foreach my $place (@places) {
    my @coords = split(/, /, $place->{COORDS});
    push(@placesWithCoords, { LAT => $coords[0], LON => $coords[1] });
}
# Direction To Start Path ( User Input )
my $pathStartDirection = TopToBottom;

# Switch Statement To Sort Places By Direction
if ($pathStartDirection == LeftToRight) {
    # Sort Places By Latitude ( Lat Low To High )
    @placesWithCoords = sort { $a->{LAT} <=> $b->{LAT} } @placesWithCoords;
} elsif ($pathStartDirection == RightToLeft) {
    # Sort Places By Latitude ( Lat High To Low )
    @placesWithCoords = sort { $b->{LAT} <=> $a->{LAT} } @placesWithCoords;
} elsif ($pathStartDirection == TopToBottom) {
    # Sort Places By Longitude ( Lon High To Low )
    @placesWithCoords = sort { $b->{LON} <=> $a->{LON} } @placesWithCoords;
} elsif ($pathStartDirection == BottomToTop) {
    # Sort Places By Longitude ( Lon Low To High )
    @placesWithCoords = sort { $a->{LON} <=> $b->{LON} } @placesWithCoords;
}

# Create CSV File
open(my $fhh, '>', "Litchi.csv") or die "Cannot open file: $!";
# Write CSV Headers
print $fhh "latitude,longitude,altitude(m),heading(deg),curvesize(m),rotationdir,gimbalmode,gimbalpitchangle,actiontype1,actionparam1,actiontype2,actionparam2,actiontype3,actionparam3,actiontype4,actionparam4,actiontype5,actionparam5,actiontype6,actionparam6,actiontype7,actionparam7,actiontype8,actionparam8,actiontype9,actionparam9,actiontype10,actionparam10,actiontype11,actionparam11,actiontype12,actionparam12,actiontype13,actionparam13,actiontype14,actionparam14,actiontype15,actionparam15,altitudemode,speed(m/s),poi_latitude,poi_longitude,poi_altitude(m),poi_altitudemode,photo_timeinterval,photo_distinterval\n";
close $fhh;

#my %usesConstant = (ActionType => Nothing);
#print $usesConstant{ActionType};

# Build The Cords Into A String That The KML Likes
my @finalString;
foreach my $place (@placesWithCoords) {
    # Build A String
    my $line = "$place->{LAT},$place->{LON},0 ";
    # Append Line to String
    push(@finalString, $line);
};

# Get The first And Last Cords
my @startPin = $placesWithCoords[0];
my @endPin = $placesWithCoords[scalar @placesWithCoords - 1];

my @startPinString = "$startPin[0]->{LAT},$startPin[0]->{LON},0";
my @endPinString = "$endPin[0]->{LAT},$endPin[0]->{LON},0";

# Add The Final String To The Template
$template_path->param(PATH => "@finalString");
# Add The Start And End Pins To The Template
$template_path->param(STARTPIN => "@startPinString");
$template_path->param(ENDPIN => "@endPinString");
# Open or create output KML file
open(my $gh, '>', "OutputPath.kml") or die "Cannot open file: $!";
print $gh $template_path->output;
# Close output file
close($gh);