#!/usr/bin/env perl

use strict;
use warnings;
use Switch;

### Default config
my $pathFtpId = "id/folder/path";
my $fileNameIgnore = ".ftpignore";

### Functions

sub printUsage {
    print STDERR "Usage: $0 [directory/path]\n"
}

sub printHelp {
    print "toto\n"
}

sub extractLastFolderName {
    my $path = $_[0];
    my @folders = split /\//, $path;

    return $folders[-1];
}

sub getConnectionId {
    my $name = $_[0];
    my $hote;
    my $user;
    my $password;
    my @contents;

    -e "$pathFtpId/$name" or die "Error: no connection id for $name\n";

    open DB, "< $pathFtpId/$name" or die "Error: Opening id file $name: $!\n";
    while (<DB>) {
	chomp $_;
	push @contents, $_;
    }
    close DB;

    foreach my $line (@contents) {
	my ($key, $value) = split /:/, $line;

	if ($value =~ /^\$/) {
	    my $extern = substr($value, 1);
	    my @oldName;
	    my $empty = "";
	    my $empty2 = "";

	    if ($#_ + 1 == 2) {
		@oldName = @{$_[1]};
		if (grep { $name eq $_ } @oldName) {
		    die "Error: Circular dependency\n";
		}
	    }
	    push @oldName, $name;
	    print "Info: research $key in $extern\n";
	    switch ($key) {
		case "HOTE" { ($hote, $empty, $empty2) = getConnectionId($extern, \@oldName)}
		case "USER" { ($empty, $user, $empty2) = getConnectionId($extern, \@oldName)}
		case "PASSWORD" { ($empty, $empty2, $password) = getConnectionId($extern, \@oldName)}
		else {
		    print STDERR "Warning: Unknown key ($key) line $. in file $pathFtpId/$name\n"
		}
	    }
	}
	else {
	    switch ($key) {
		case "HOTE" { $hote = $value }
		case "USER" { $user = $value }
		case "PASSWORD" { $password = $value }
		else {
		    print STDERR "Warning: Unknown key ($key) line $. in file $pathFtpId/$name\n"
		}
	    }
	}
    }

    return $hote, $user, $password;
}

sub listFiles {
    my $path = $_[0];
    my @files;
    my @contents;
    my @ignored;

    if ($#_ + 1 == 2) {
	@ignored = @{$_[1]};
    }
    
    opendir DIR, $path or die "Error: Listing $path: $!\n";
    @contents = grep { !/^\.\.?$/ } readdir DIR;
    closedir DIR;
    
    # loading regex content in $fileNameIgnored
    if (-f "$path/$fileNameIgnore") {
	open IGNORE, "< $path/$fileNameIgnore" or die "Error: Opening $fileNameIgnore: $!\n";
	while (<IGNORE>) {
	    chomp $_;
	    s/\*/\\\\*/;
	    s/\./\\\./;
	    push @ignored, $_;
	}
	close IGNORE;
    }

    # ignore pattern file
    foreach my $ignore (@ignored) {
	@contents = grep !/$ignore/, @contents
    }
    
    # list rest file
    foreach my $elem (@contents) {
	if (-f "$path/$elem") {
	    push @files, "$path/$elem";
	}
	elsif (-d "$path/$elem") {
	    # recursivity
	    push @files, listFiles("$path/$elem", \@ignored);
	}
    }
    
    return @files;
}


### Main

# Parse arguments
my $folder = `pwd`;
if ($#ARGV + 1 == 1) {
    $folder = $ARGV[0];
}

$folder =~ s/\/*$//;
-d $folder || die "$!\n";

my $folderName = extractLastFolderName($folder);

# List File to upload
my @files = listFiles($folder);
my $file;

foreach $file (@files) {
    print "$file\n";
}

# Connection id
my ($hote, $user, $password) = getConnectionId($folderName);
print "hote=$hote, user=$user, password=$password\n";


# Connection FTP

exit 0;
