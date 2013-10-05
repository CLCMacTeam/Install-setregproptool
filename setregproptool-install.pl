#!/usr/bin/perl

# ----------------------------------------------------------
#
# Written by Justin Elliott <jde6@psu.edu>
# TLT/Classroom and Lab Computing, Penn State University
#
# This script is included with PSU Blast Image Config 3.0:
#
#   http://clc.its.psu.edu/UnivServices/itadmins/mac/blastimageconfig
#
# Use of this script for other purposes is permitted as long as credit to Justin Elliott is mentioned.
# ----------------------------------------------------------

use strict; # Declare strict checking on variable names, etc.
use File::Basename; # Used to get this script's filename

my ( $programName ) = basename($0);

print "***\n";

# ----------------------------------------------------------
# Check that we're running as root (or via sudo)
# ----------------------------------------------------------

if ( $< != 0 ) # '$<' is the effective user id in Perl (euid)
{
        print "Sorry, but this script must be executed via 'sudo' or as the root user. Exiting.\n***\n";
        exit -1;
}

# ----------------------------------------------------------
# Check that we're running on 10.7 or later:
# ----------------------------------------------------------

my $fullOSXversionStr = `/usr/bin/sw_vers -productVersion`;
$fullOSXversionStr =~ s/\s+//; # Remove all whitespace characters

# (my $MajorVersion, my $MinorVersion, my $BugFixVersion) = ("10","6","8"); # For Testing Purposes, to get the check to fail
(my $MajorVersion, my $MinorVersion, my $BugFixVersion) = split('\.', $fullOSXversionStr);

print "OS X System Version: Major = '$MajorVersion', Minor = '$MinorVersion', Bug Fix = '$BugFixVersion'\n";

my $ErrMsg = "ERROR: Sorry, but this script only supports Mac OS X 10.7 and higher.\n\n***$programName exiting.\n";

if ( ($MajorVersion < 10) || ( ( $MajorVersion == 10 ) && ( $MinorVersion < 7 ) ) )
{
	print "$programName: $ErrMsg";
	exit (-1);	
}

# ----------------------------------------------------------
# Check that we've received the required argv path:
# ----------------------------------------------------------

my $argc;   # Declare variable $argc. This represents
            # the number of commandline parameters entered.

my ( $dirName ) = dirname($0);
my ( $fullPathToMe ) = $dirName . "\/" . $programName;

$argc = @ARGV; # Get the number of commandline parameters

if (@ARGV<1)
{
  # The number of commandline parameters is 1,
  # so print a usage message.
  usage();  # Call subroutine usage()
  exit(-1);   # When usage() has completed execution,
            # exit the program.
}

# ----------------------------------------------------------
# Make sure that the destination is a directory and is writable:
# ----------------------------------------------------------

my $destDir = $dirName;

if ( ( -d $destDir ) && ( -w $destDir ) )
{
	print "$programName: Success: The destination path '$destDir' is a writable directory.\n\n";
}
else
{
	print "$programName: ERROR! The destination path '$destDir' is not a writable directory. Exiting.\n\n";
	exit -1;
}

if ( $destDir ne "." ) # The user is running this script from the full path to it versus in the pwd:
{
	$destDir = $dirName . "/.";
}

$destDir = "\"" . $destDir . "\""; # add quotes to the path as there is white space that hasn't been delimited

# ----------------------------------------------------------
# Build the input parameters list:
# ----------------------------------------------------------

my $OSXInstallerPath = $ARGV[0]; # /Volumes/SL Mac HD

print "$programName: Path to this script = '$fullPathToMe'\n"; 
print "$programName: Received path = '$OSXInstallerPath'\n"; 

# ----------------------------------------------------------
# Mount the OS X InstallESD.dmg first:
# ----------------------------------------------------------

my $OSXESDImagePath = "\"" . $OSXInstallerPath . "/Contents/SharedSupport/InstallESD.dmg" . "\"";

print "\n$programName: Mounting the 'InstallESD.dmg' at the path of '$OSXESDImagePath' ...\n\n";

my $mountOSXESDResult = system("/usr/bin/hdiutil attach " . $OSXESDImagePath . " -nobrowse") >> 8;

if ($mountOSXESDResult != 0)
{
	print "$programName: ERROR: Unable to mount the OS X ESD Disk Image!\n";
	exit -1;
}
else
{
	print "\n$programName: Successfully mounted the OS X ESD Image.\n";
}

# ----------------------------------------------------------
# Mount the 'BaseSystem.dmg' next:
# ----------------------------------------------------------

my $OSXESDInstallVolPath = "";

if ( ( $MajorVersion == 10 ) && ( $MinorVersion < 9 ) )
{
	$OSXESDInstallVolPath = "/Volumes/Mac OS X Install ESD";
}
else
{
	$OSXESDInstallVolPath = "/Volumes/OS X Install ESD";
}

my $OSXBaseSystemImagePath = "\"" . $OSXESDInstallVolPath . "/BaseSystem.dmg\"";

print "\n$programName: Mounting the 'BaseSystem.dmg' at the path of '$OSXBaseSystemImagePath' ...\n\n";

my $mountOSXBaseSystemResult = system("/usr/bin/hdiutil attach " . $OSXBaseSystemImagePath . " -nobrowse") >> 8;

if ($mountOSXBaseSystemResult != 0)
{
	print "$programName: ERROR: Unable to mount the OS X BaseSystem Disk Image!\n";
	exit -1;
}
else
{
	print "\n$programName: Successfully mounted the OS X BaseSystem Image.\n";
}

# ----------------------------------------------------------
# Copy the 'setregproptool' to the current directory of this script:
# ----------------------------------------------------------

print "\n$programName: Copying 'setregproptool' to the same directory as this script ...\n\n";

my $MacOSBaseSystemVolumePath = "";

if ( ( $MajorVersion == 10 ) && ( $MinorVersion < 9 ) )
{
	$MacOSBaseSystemVolumePath = "/Volumes/Mac OS X Base System";
}
else
{
	$MacOSBaseSystemVolumePath = "/Volumes/OS X Base System";
}

my $SetRegPropToolPath = "\"" . $MacOSBaseSystemVolumePath . "/Applications/Utilities/Firmware Password Utility.app/Contents/Resources/setregproptool\"";

print "$programName: Attempting to copy 'setregproptool' from the path of '$SetRegPropToolPath' next ...\n";

my $CopySetRegPropToolResult = system("/bin/cp -p " . $SetRegPropToolPath . " " . $destDir) >> 8;

if ($CopySetRegPropToolResult != 0)
{
	print "$programName: ERROR: Failed to copy the setregproptool to the current directory!\n";
	exit -1;
}
else
{
	print "\n$programName: Successfully copied 'setregproptool' to the current directory.\n";
}

# ----------------------------------------------------------
# Detach the BaseSystem.dmg image:
# ----------------------------------------------------------

print "\n$programName: Unmounting the 'BaseSystem.dmg' \(\"Mac OS X Base System\"\ in the Finder) ...\n\n";

# hdiutil detach "/Volumes/Mac OS X Base System"
my $DetachBaseSystemDmgResult = system("/usr/bin/hdiutil detach \"" . $MacOSBaseSystemVolumePath . "\"") >> 8;

if ($DetachBaseSystemDmgResult != 0)
{
	print "$programName: ERROR: Failed to unmount the 'BaseSystem.dmg' image!\n";
	exit -1;
}
else
{
	print "\n$programName: Successfully unmounted the 'BaseSystem.dmg' image.\n";
}

# ----------------------------------------------------------
# Detach the InstallESD.dmg image:
# ----------------------------------------------------------
# hdiutil detach /Volumes/Mac\ OS\ X\ Install\ ESD

print "\n$programName: Unmounting the 'InstallESD.dmg' \(\"Mac OS X Install ESD\"\ in the Finder) ...\n\n";

# hdiutil detach "/Volumes/Mac OS X Base System"
my $DetachOSXESDDmgResult = system("/usr/bin/hdiutil detach \"" . $OSXESDInstallVolPath . "\"") >> 8;

if ($DetachOSXESDDmgResult != 0)
{
	print "$programName: ERROR: Failed to unmount the 'InstallESD.dmg' image!\n";
	exit -1;
}
else
{
	print "\n$programName: Successfully unmounted the 'InstallESD.dmg' image.\n";
}

print "\n$programName: Successfully installed 'setregproptool'.\n";

print "\n*** $programName: Done!\n\n";

exit 0;

# END OF MAIN SCRIPT CODE

# ----------------------------------------------------------
# PROCEDURES/FUNCTIONS BELOW
# ----------------------------------------------------------
	
sub usage
{
  print "$programName: ERROR: Minimum number of parameters not received.\n";
  print "$programName: Usage: sudo ./$programName /path/to/Install OS X.app\n";
}
