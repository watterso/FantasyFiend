use IO::Prompt;
use WWW::Mechanize;
use strict;
use Data::Dumper;
use HTML::TableExtract;
use Path::Class;

sub checkWeek{
	$_[0] =~ m!.*<h2.*>(.*)</h2>!;
	my @temp1 = split / /, $1;
	return $temp1[1];
}
my $mech = WWW::Mechanize->new();
$mech->get("http://www.nfl.com/scores");
my $week = checkWeek($mech->content);
my $weekVer = prompt("Is this for Week #" . $week. "?(y/n) ", -yn);
if(!$weekVer){
	$week = prompt("Please enter the week number: ", -i);
}
if(1){
my $league = prompt("Please enter your league number: ", -raw);
my $usrn = prompt("Username: ", -raw);
my $pswd = prompt("Password: ", -rawe => '*');
local @ARGV = ($usrn,$pswd,$week,$league);
do 'scraperJSON.pl';
}

#read in arr of team names
my $dir = dir("week" . $week);
my $file = $dir->file("hash.txt");
my $str = $file->slurp();
my $VAR1;
eval $str;
my @VAR1 = $VAR1;
my @teams = ();
for(my $i=0; $i<length($VAR1[0]); $i++) {
	if(length($VAR1[0][$i])>0){
		#print $VAR1[0][$i] . "($i)\n";
		$teams[$i] = $VAR1[0][$i];
	}
}
for(my $i=0; $i<(scalar @teams); $i++){
	#print ($i+1) . ". ".$teams[$i];
	print "\t ". ($i+1). ") " . $teams[$i]."\n";
}
my $team = prompt("Choose team: ",-raw);
local @ARGV = ($team,$week);
do 'analyzeJSON.pl';