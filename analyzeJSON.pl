use Data::Dumper;
use Path::Class;
use Path::Class::Dir;
use List::Util qw(sum);
use JSON;
use Switch;
use strict;
use Math::Complex;
use Math::NumberCruncher;
use IO::Scalar;

sub addValues{
	my %ref = %{$_[0]};
	my @ref_arr = @{$ref{val}};
	push(@ref_arr, $_[1]);
	#print Dumper \@ref_arr;
	$ref{sum} += $_[1];
	$ref{cnt}++;
	$ref{val} = \@ref_arr;
	$_[0] = \%ref;
}
sub doStats{
	my $math_ref = Math::NumberCruncher->new();
	my %ref = %{$_[0]};
	my @ref_arr = @{$ref{val}};
	$ref{mean} = $math_ref->Mean(\@ref_arr);		#mean
	$ref{medi} = $math_ref->Median(\@ref_arr);		#median
	
	my $std = $math_ref->StandardDeviation(\@ref_arr); #stdDev
	my $stdVal;
	my $temp = new IO::Scalar \$stdVal;
	$temp->print($std);				#printing to var to lose the bless
	$ref{stdDev} = $stdVal;
	
	$_[0] = \%ref;
}
sub compPrint{
	my %ref = %{$_[0]};
	my $presPos = $_[1];
	my @dat = @{$_[2]};
	
	print $presPos. "- ". $dat[0] . " " . $dat[1] ."\n";
	
}

@ARGV or die "Usage: $0 team week\n";

my $teamNum = $ARGV[0];
my $weekNum = $ARGV[1];


#calc num of teams
my $dir = dir("week" . $weekNum."JSON");
my $nfiles = $dir->traverse(sub {
    my ($child, $cont) = @_;
    return sum($cont->(), ($child->is_dir ? 0 : 1));
  });
$nfiles-=1;	#offset for hash file;

#for stats
my $QB_ref = { sum => 0, cnt => 0, val => []};
my $RB_ref = { sum => 0, cnt => 0, val => []};
my $WR_ref = { sum => 0, cnt => 0, val => []};
my $TE_ref = { sum => 0, cnt => 0, val => []};
my $K_ref = { sum => 0, cnt => 0, val => []};
my $DEF_ref = { sum => 0, cnt => 0, val => []};


#print "LINE 29\n";							#DEBUG
my %myTeam;
my @teams = ();						#array of hash references
my $json = JSON->new->allow_nonref;
my $file1 = $dir->file("hash.txt");
my $str1 = $file1->slurp();
my @teamNames = @{$json->decode( $str1 )};
my $herp = scalar @teamNames;
for(my $i=0;$i<$herp;$i++){
	#print "Getting numbers from: " . $teamNames[$i] . " ($i)\n"; #DEBUG
	my $file = $dir->file("team".($i+1).".txt");
	my $str = $file->slurp();
	$teams[$i] = $json->decode( $str );
	my %team = %{$teams[$i]};
	if($i==$teamNum){
		%myTeam = %team;
	}
	for my $key (keys %team) {
   	 	my @data = @{$team{$key}};
   	 	my @info = split / /, $data[1];
   	 	my $pos = $info[-1];
   	 	switch($pos){
   	 		case "QB"	{addValues($QB_ref,$data[0])}
   	 		case "RB"	{addValues($RB_ref,$data[0])}
   	 		case "WR"   {addValues($WR_ref,$data[0])}
   	 		case "TE"	{addValues($TE_ref,$data[0])}
   	 		case "K"	{addValues($K_ref,$data[0])}
   	 		case "DEF"	{addValues($DEF_ref,$data[0])}
   	 		else		{print $pos . " is invalid!\n"}
   	 	}
	}
}
doStats($QB_ref);
doStats($RB_ref);
doStats($WR_ref);
doStats($TE_ref);
doStats($K_ref);
doStats($DEF_ref);

my %QB = %{$QB_ref};
my %RB = %{$RB_ref};
my %WR = %{$WR_ref};
my %TE = %{$TE_ref};
my %K = %{$K_ref};
my %DEF = %{$DEF_ref};
print "\n\tStats\n";
print "+-------------------------------------------------------------+\n";
print "QB- Sum: ". $QB{sum} ."  Cnt: " . $QB{cnt} ."  Avg: ".($QB{mean})."  Std Dev: ".($QB{stdDev})."\n";
print "RB- Sum: ". $RB{sum} ."  Cnt: " . $RB{cnt} ."  Avg: ".($RB{mean})."  Std Dev: ".($RB{stdDev})."\n";
print "WR- Sum: ". $WR{sum} ."  Cnt: " . $WR{cnt} ."  Avg: ".($WR{mean})."  Std Dev: ".($WR{stdDev})."\n";
print "TE- Sum: ". $TE{sum} ."  Cnt: " . $TE{cnt} ."  Avg: ".($TE{mean})."  Std Dev: ".($TE{stdDev})."\n";
print "KR- Sum: ". $K{sum} ."  Cnt: " . $K{cnt} ."  Avg: ".($K{mean})."  Std Dev: ".($K{stdDev})."\n";
print "DF- Sum: ". $DEF{sum} ."  Cnt: " . $DEF{cnt} ."  Avg: ".($DEF{mean})."  Std Dev: ".($DEF{stdDev})."\n\n";

for my $key (keys %myTeam) {
	my @data = @{$myTeam{$key}};
	my @info = split / /, $data[1];
	my $pos = $info[-1];
	switch($pos){
		case "QB"	{compPrint($QB_ref, $key, \@data)}
		case "RB"	{compPrint($RB_ref, $key, \@data)}
		case "WR"   {compPrint($WR_ref, $key, \@data)}
		case "TE"	{compPrint($TE_ref, $key, \@data)}
		case "K"	{compPrint($K_ref, $key, \@data)}
		case "DEF"	{compPrint($DEF_ref, $key, \@data)}
		else		{print $pos . " is invalid!\n"}
	}
}

my $dir = dir("week" . $weekNum."JSON", "stats");
$dir->mkpath();
my $json_text1   = $json->encode($QB_ref);
my $file = $dir->file("QB.txt");
my $file_handle = $file->openw();
$file_handle->print($json_text1);

$json_text1   = $json->encode($RB_ref);
$file = $dir->file("RB.txt");
$file_handle = $file->openw();
$file_handle->print($json_text1);

$json_text1   = $json->encode($WR_ref);
$file = $dir->file("WR.txt");
$file_handle = $file->openw();
$file_handle->print($json_text1);

$json_text1   = $json->encode($TE_ref);
$file = $dir->file("TE.txt");
$file_handle = $file->openw();
$file_handle->print($json_text1);

$json_text1   = $json->encode($K_ref);
$file = $dir->file("K.txt");
$file_handle = $file->openw();
$file_handle->print($json_text1);

$json_text1   = $json->encode($DEF_ref);
$file = $dir->file("DEF.txt");
$file_handle = $file->openw();
$file_handle->print($json_text1);