use Data::Dumper;
use Path::Class;
use Path::Class::Dir;
use List::Util qw(sum);
use JSON;
use Switch;
use strict;

sub addValues{
	my %ref = %{$_[0]};
	$ref{sum} += $_[1];
	$ref{cnt}++;
	$_[0] = \%ref;
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
my $QB_ref = { sum => 0, cnt => 0};
my $RB_ref = { sum => 0, cnt => 0};
my $WR_ref = { sum => 0, cnt => 0};
my $TE_ref = { sum => 0, cnt => 0};
my $K_ref = { sum => 0, cnt => 0};
my $DEF_ref = { sum => 0, cnt => 0};




#print "LINE 29\n";							#DEBUG

my @teams = ();						#array of hash references
my $json = JSON->new->allow_nonref;
my $file1 = $dir->file("hash.txt");
my $str1 = $file1->slurp();
my @teamNames = @{$json->decode( $str1 )};
for(my $i=0;$i<$nfiles;$i++){
	#print "Getting numbers from: " . $teamNames[$i] . " ($i)\n"; #DEBUG
	my $file = $dir->file("team".($i+1).".txt");
	my $str = $file->slurp();
	$teams[$i] = $json->decode( $str );
	my %team = %{$teams[$i]};
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
my %QB = %{$QB_ref};
my %RB = %{$RB_ref};
my %WR = %{$WR_ref};
my %TE = %{$TE_ref};
my %K = %{$K_ref};
my %DEF = %{$DEF_ref};
print "\n\tStats\n";
print "+-------------------------------------------------------------+\n";
print "QB-\tSum: ". $QB{sum} ."\tCnt: " . $QB{cnt} ."\tAvg: ".($QB{sum}/$QB{cnt})."\n";
print "RB-\tSum: ". $RB{sum} ."\tCnt: " . $RB{cnt} ."\tAvg: ".($RB{sum}/$RB{cnt})."\n";
print "WR-\tSum: ". $WR{sum} ."\tCnt: " . $WR{cnt} ."\tAvg: ".($WR{sum}/$WR{cnt})."\n";
print "TE-\tSum: ". $TE{sum} ."\tCnt: " . $TE{cnt} ."\tAvg: ".($TE{sum}/$TE{cnt})."\n";
print "KR-\tSum: ". $K{sum} ."\tCnt: " . $K{cnt} ."\tAvg: ".($K{sum}/$K{cnt})."\n";
print "DF-\tSum: ". $DEF{sum} ."\tCnt: " . $DEF{cnt} ."\tAvg: ".($DEF{sum}/$DEF{cnt})."\n\n";