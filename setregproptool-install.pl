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

# ----------------------------------------------------------
# Revision History:
# 2012-02-29: <jde6 [at] psu.edu> Initial Version
# ----------------------------------------------------------

use strict; # Declare strict checking on variable names, etc.
use File::Basename; # Used to get this script's filename

my ( $programName ) = basename($0);

print "\n*** $programName: Starting...\n\n";

# ----------------------------------------------------------
# Check that we're running as root (or via sudo)
# ----------------------------------------------------------

if ( $< != 0 ) # $> = effective user id (euid)
{
        print "$programName: Sorry, but this script must be ran via 'sudo' or as the root user. Exiting.\n***\n";
        exit -1;
}

# ----------------------------------------------------------
# Check that we're running on 10.7 or later:
# ----------------------------------------------------------

$_=`/usr/bin/sw_vers -productVersion`;
/(\d+).(\d+).(\d+)/; # ie, $1="10" $2="6" $3="8"

print "This Mac appears to be running $1.$2.$3.\n\n";

my $ErrMsg = "ERROR: Sorry, but this script only supports Mac OS X 10.7 and higher.\n\n***$programName exiting.\n";

if ( ($1 < 10) || ( ( $1 == 10 ) && ( $2 < 7 ) ) )
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
# Build the input parameters list:
# ----------------------------------------------------------

my $OSXInstallerPath = $ARGV[0]; # /Volumes/SL Mac HD

print "$programName: Path to this script = '$fullPathToMe'\n"; 
print "$programName: Received path = '$OSXInstallerPath'\n"; 

# ----------------------------------------------------------
# Mount the Lion InstallESD.dmg first:
# ----------------------------------------------------------

my $LionESDImagePath = "\"" . $OSXInstallerPath . "/Contents/SharedSupport/InstallESD.dmg" . "\"";

print "\n$programName: Mounting the 'InstallESD.dmg' at the path of '$LionESDImagePath' ...\n\n";

my $mountLionESDResult = system("/usr/bin/hdiutil attach " . $LionESDImagePath) >> 8;

if ($mountLionESDResult != 0)
{
	print "$programName: ERROR: Unable to mount the Lion ESD Disk Image!\n";
	exit -1;
}
else
{
	print "\n$programName: Successfully mounted the Lion ESD Image.\n";
}

# ----------------------------------------------------------
# Mount the 'BaseSystem.dmg' next:
# ----------------------------------------------------------

my $LionESDInstallVolPath = "/Volumes/Mac OS X Install ESD";
my $LionBaseSystemImagePath = "\"" . $LionESDInstallVolPath . "/BaseSystem.dmg\"";

print "\n$programName: Mounting the 'BaseSystem.dmg' at the path of '$LionBaseSystemImagePath' ...\n\n";

my $mountLionBaseSystemResult = system("/usr/bin/hdiutil attach " . $LionBaseSystemImagePath) >> 8;

if ($mountLionBaseSystemResult != 0)
{
	print "$programName: ERROR: Unable to mount the Lion BaseSystem Disk Image!\n";
	exit -1;
}
else
{
	print "\n$programName: Successfully mounted the Lion BaseSystem Image.\n";
}

# ----------------------------------------------------------
# Copy the 'setregproptool' to the current directory of this script:
# ----------------------------------------------------------

print "\n$programName: Copying 'setregproptool' to the same directory as this script ...\n\n";

my $MacOSBaseSystemVolumePath = "/Volumes/Mac OS X Base System";

my $SetRegPropToolPath = "\"" . $MacOSBaseSystemVolumePath . "/Applications/Utilities/Firmware Password Utility.app/Contents/Resources/setregproptool\"";

print "$programName: Attempting to copy 'setregproptool' from the path of '$SetRegPropToolPath' next ...\n";

my $destDir = $dirName;

if ( $destDir ne "." ) # The user is running this script from the full path to it versus in the pwd:
{
	$destDir = $dirName . "/.";
}

$destDir = "\"" . $destDir . "\""; # add quotes to the path as there is white space that hasn't been delimited

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
my $DetachOSXESDDmgResult = system("/usr/bin/hdiutil detach \"" . $LionESDInstallVolPath . "\"") >> 8;

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
  print "$programName: Usage: sudo ./$programName /path/to/Install Mac OS X Lion.app\n";
}