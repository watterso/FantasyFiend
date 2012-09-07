use WWW::Mechanize;
use HTML::TableExtract;
use strict;
use Path::Class;
use JSON;
use warnings;

sub getCount{
	$_[0] =~ m!<select id="teamId" name="teamId">(.*)</select>!;
	my @temp1 = split /<.*?>/, $1;
	return @temp1;
}

@ARGV or die "Usage: $0 usr pswd week league\n";
my $usrn = $ARGV[0];
my $pswd = $ARGV[1];
my $week = $ARGV[2];
my $url = "http://fantasy.nfl.com/league/" . $ARGV[3];

my $mech = WWW::Mechanize->new();
$mech->get($url);
$mech->submit_form(
        form_number => 1,
        fields      => {
            username    => $usrn,
            password    => $pswd,
        }
);
my $tUrl = $url . "/team/";
$mech->get($tUrl . "1");
my @tmpNames = getCount($mech->content);
my @teamNames = ();
foreach my $tm(@tmpNames){
	#print "Comparing " . $tm ."\n";
	if(length($tm)>0){
		#print "Pushing " . $tm . "\n";
		push(@teamNames, $tm);
	}
}
my $numTeams = (scalar @teamNames);
my $dir1 = "week".$week."JSON";
mkdir $dir1;
my $dir = dir($dir1);
print "Parsing Teams:\n";
for(my $j = 1; $j<=$numTeams; $j++){
	print $teamNames[$j-1]."($j)";
	$mech->get($tUrl . $j);
	print ".";
	my $te = HTML::TableExtract->new();
	my $html = $mech->content;
	$te->parse($html);
	print ".";
	my %disTeam;
	# Examine all matching tables
	foreach my $ts ($te->tables) {
		print ".";
		#print "Table (", join(',', $ts->coords), "): ";
		my @rows = $ts->rows();
		my $lim = scalar @rows;
		#print $lim . " rows long\n";
		if($ts->count==0){
			if($j==5){
				my @info = split / -/, $ts->cell(2,3);
				$disTeam{"QB"} = [$ts->cell(2,-1), $info[0]];
				@info = split / -/, $ts->cell(3,3);
				$disTeam{"RB1"} = [$ts->cell(3,-1), $info[0]];
				@info = split / -/, $ts->cell(4,3);
				$disTeam{"RB2"} = [$ts->cell(4,-1), $info[0]];
				@info = split / -/, $ts->cell(5,3);
				$disTeam{"WR1"} = [$ts->cell(5,-1), $info[0]];
				@info = split / -/, $ts->cell(6,3);
				$disTeam{"WR2"} = [$ts->cell(6,-1), $info[0]];
				@info = split / -/, $ts->cell(7,3);
				$disTeam{"TE"} = [$ts->cell(7,-1), $info[0]];
				@info = split / -/, $ts->cell(8,3);
				$disTeam{"W/R"} = [$ts->cell(8,-1), $info[0]];
				#Skip 9 for "Bench" row
				for(my $i=10; $i<$lim; $i++){
					@info = split / -/, $ts->cell($i,3);
					$disTeam{"BN".($i-9)} = [$ts->cell($i,-1), $info[0]];
				
				}
				
			}else{
				my @info = split / -/, $ts->cell(2,2);
				$disTeam{"QB"} = [$ts->cell(2,-1), $info[0]];
				@info = split / -/, $ts->cell(3,2);
				$disTeam{"RB1"} = [$ts->cell(3,-1), $info[0]];
				@info = split / -/, $ts->cell(4,2);
				$disTeam{"RB2"} = [$ts->cell(4,-1), $info[0]];
				@info = split / -/, $ts->cell(5,2);
				$disTeam{"WR1"} = [$ts->cell(5,-1), $info[0]];
				@info = split / -/, $ts->cell(6,2);
				$disTeam{"WR2"} = [$ts->cell(6,-1), $info[0]];
				@info = split / -/, $ts->cell(7,2);
				$disTeam{"TE"} = [$ts->cell(7,-1), $info[0]];
				@info = split / -/, $ts->cell(8,2);
				$disTeam{"W/R"} = [$ts->cell(8,-1), $info[0]];
				#Skip 9 for "Bench" row
				for(my $i=10; $i<$lim; $i++){
					@info = split / -/, $ts->cell($i,2);
					$disTeam{"BN".($i-9)} = [$ts->cell($i,-1), $info[0]];
				
				}
			}
		}
		if($ts->count==1){
			if($j==5){
				my @info = split / -/, $ts->cell(2,3);
				$disTeam{"K"} = [$ts->cell(2,-1), $info[0]];
			}else{
				my @info = split / -/, $ts->cell(2,2);
				$disTeam{"K"} = [$ts->cell(2,-1), $info[0]];	
			}
		}
		if($ts->count==2){
			if($j==5){
				my @info = split /-/, $ts->cell(2,3);
				$disTeam{"DEF"} = [$ts->cell(2,-1), $info[0]];
			}else{
				my @info = split /-/, $ts->cell(2,2);
				$disTeam{"DEF"} = [$ts->cell(2,-1), $info[0]];	
			}
		}
	}
 	#$fTeams[$j-1] = {%disTeam};
 	my $json = JSON->new->allow_nonref;
 	my $json_text   = $json->encode(\%disTeam);
 	my $file = $dir->file("team". $j .".txt");
	my $file_handle = $file->openw();
	$file_handle->print($json_text);
 	#print $json_text . "\n";
 	print "done!\n";
 	#print Dumper \%disTeam;
 	
}
my $json = JSON->new->allow_nonref;
my $json_text   = $json->encode(\@teamNames);
my $file = $dir->file("hash.txt");
my $file_handle = $file->openw();
$file_handle->print($json_text);