#!/usr/bin/perl
#
use strict;
use UUID 'uuid';

my $drive_folder = "https://drive.google.com/drive/folders/1Q8JHxwhE6Jr9Uu1FOj_VMtTQFgFJ33cJ/";

my $dir = $ARGV[0];
my $dh;
opendir($dh, $dir);
my @files = readdir($dh);
closedir($dh);

foreach my $file (@files) {
    if($file =~ /^DJI.*\.(jpg|JPG|jpeg)$/) {
        my $uuid = uuid();
        print "$dir/$file -> $dir/$uuid\.jpg\n";
        system("mv $dir/$file $dir/$uuid\.jpg");
    }
}
