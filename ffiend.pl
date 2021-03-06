use IO::Prompter;
use WWW::Mechanize;
use strict;
use Data::Dumper;
use HTML::TableExtract;
use Path::Class;
use Path::Class::Dir;
use List::Util qw(sum);
use JSON;
use IO::Scalar;
use Switch;
use Math::Complex;
use Math::NumberCruncher;
use Text::Levenshtein qw(distance);
use Env;
#Globals
my %myTeam;		#hash of team members for selected team see "analyzer"
my $myTeamNum;
my $theWeek;
my @teams;		#arr of team hashes  see "analyzer"
my @teamNames;	#arr of team names
my $QB_ref = { sum => 0, cnt => 0, val => []};
my $RB_ref = { sum => 0, cnt => 0, val => []};
my $WR_ref = { sum => 0, cnt => 0, val => []};
my $TE_ref = { sum => 0, cnt => 0, val => []};
my $K_ref = { sum => 0, cnt => 0, val => []};
my $DEF_ref = { sum => 0, cnt => 0, val => []};		#references to stats for respective positions
my %frees;

sub deBless{		#(ref, val)
	my $temp = new IO::Scalar $_[0];
	$temp->print($_[1]);		
}
sub help(){
	print "Commands & Usage:\n";
	print "scrape  --- scrapes team and players\n";
	print "analyze --- analyzes data\n";
	print "run  --- does scrape then analyze\n";
	print "comp first1 last1 first2 last2 --- compares two players\n";
	print "stats --- prints league stats for the positions\n";
	print "team [team_num] --- prints roster of team team_num, defaults to prev selected team\n";
    print "scores --- prints out all the teams and their scores\n";
	
	print "**Note <TAB> completion and command history via <CTRL-R>**\n";
}
sub printStats{
	my %QB = %{$QB_ref};
	my %RB = %{$RB_ref};
	my %WR = %{$WR_ref};
	my %TE = %{$TE_ref};
	my %K = %{$K_ref};
	my %DEF = %{$DEF_ref};
	print "\tStats\n";
	print "+-------------------------------------------------------------+\n";
	print "QB- Sum: ". $QB{sum} ."  Cnt: " . $QB{cnt} ."  Avg: ".($QB{mean})."  Std Dev: ".($QB{stdDev})." Median: ".$QB{medi}."\n";
	print "RB- Sum: ". $RB{sum} ."  Cnt: " . $RB{cnt} ."  Avg: ".($RB{mean})."  Std Dev: ".($RB{stdDev})." Median: ".$RB{medi}."\n";
	print "WR- Sum: ". $WR{sum} ."  Cnt: " . $WR{cnt} ."  Avg: ".($WR{mean})."  Std Dev: ".($WR{stdDev})." Median: ".$WR{medi}."\n";
	print "TE- Sum: ". $TE{sum} ."  Cnt: " . $TE{cnt} ."  Avg: ".($TE{mean})."  Std Dev: ".($TE{stdDev})." Median: ".$TE{medi}."\n";
	print "KR- Sum: ". $K{sum} ."  Cnt: " . $K{cnt} ."  Avg: ".($K{mean})."  Std Dev: ".($K{stdDev})." Median: ".$K{medi}."\n";
	print "DF- Sum: ". $DEF{sum} ."  Cnt: " . $DEF{cnt} ."  Avg: ".($DEF{mean})."  Std Dev: ".($DEF{stdDev})." Median: ".$DEF{medi}."\n";
}
sub printTeam{
	my %theTeam = %{$teams[$_[0]]};
    my $tScore = teamScore($_[0]);
	print "\t\tRoster for ". $teamNames[$_[0]]."\n";
    print "\t\tTeam Score: $tScore\n";
	print "\t\t==========================\n";
	my @data = @{$theTeam{QB}};
	compPrint($QB_ref, "QB", \@data);
	@data = @{$theTeam{RB1}};
	compPrint($RB_ref, "RB1", \@data);
	@data = @{$theTeam{RB2}};
	compPrint($RB_ref, "RB2", \@data);
	@data = @{$theTeam{WR1}};
	compPrint($WR_ref, "WR1", \@data);
	@data = @{$theTeam{WR2}};
	compPrint($WR_ref, "WR2", \@data);
	@data = @{$theTeam{TE}};
	compPrint($TE_ref, "TE", \@data);
	
	@data = @{$theTeam{"W/R"}};
	my @info = split / /, $data[1];
	my $pos = $info[-1];
	if($pos == "RB"){
		compPrint($RB_ref, "W/R", \@data);
	}elsif($pos == "WR"){
		compPrint($WR_ref, "W/R", \@data);
	}
		
	@data = @{$theTeam{K}};
	compPrint($K_ref, "K", \@data);
	@data = @{$theTeam{DEF}};
	compPrint($DEF_ref, "DEF", \@data);
	print "\t\t\tBench\n";
	print "\t\t==========================\n";
	my $numK = keys(%theTeam);
	$numK-=9;
	for(my $x=1;$x<=$numK; $x++){
		my $key = "BN".$x;
		my @data = @{$theTeam{$key}};
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
}
sub freeComp{
    my @dat = @{$_[1]};
    my @info = split / /, $dat[1];
    my $pos = $info[-1];
    my $ref;
    switch($pos){
        case "QB"	{$ref = $QB_ref}
        case "RB"	{$ref = $RB_ref}
        case "WR"   {$ref = $WR_ref}
        case "TE"	{$ref = $TE_ref}
        case "K"	{$ref = $K_ref}
        case "DEF"	{$ref = $DEF_ref}
    }
        #print "Getting frees for '$pos'\n";
    my @theFrees = @{$frees{$pos}};
    my %reps = ();
    #print "comp $theFrees[0][1] to $dat[0]\n";
    if($theFrees[0][0]-2>$dat[0]){
        my $index = 0;
        my $pts = $theFrees[0][0];
        while($pts-2>$dat[0] and $index<3){
            my $perc = percentile($ref,$pts,0);
            my @der = ($pts,$perc);
            $reps{$theFrees[$index][1]} = \@der;
            $index++;
            $pts = $theFrees[$index][0];
            #print scalar( keys %reps)."\n";
        }
        print "Consider replacing $dat[1] - $dat[0] (".percentile($ref,$dat[0],1)."%) with:\n";
        foreach my $fruit (sort {$reps{$b}[0] <=> $reps{$a}[0]} keys %reps) {
            my @arr = @{$reps{$fruit}};
            print  "\t\t".$fruit. " - " . $arr[0]." ($arr[1]%)"."\n";
        }
    }
    #print Dumper @theFrees;
    
}
sub checkWeek{
	my $mech = WWW::Mechanize->new();
	$mech->get("http://www.nfl.com/scores");
	my $weekCon = $mech->content;
	my $week = 0;
	$weekCon =~ m!.*<h2.*>(.*)</h2>!;
	my @temp1 = split / /, $1;
	my $weekVer = prompt("Is this for Week #" . $temp1[1]. "?(y/n) ", -yn);
	if(!$weekVer){
		$week = prompt("Please enter the week number: ", -raw);
	}else{
		$week = $temp1[1];
	}
    $theWeek = $week;
	return $week;
}
sub getCount{
	$_[0] =~ m!<select id="teamId" name="teamId">(.*)</select>!;
	my @temp1 = split /<.*?>/, $1;
	return @temp1;
}
sub percentile{
    my %ref = %{$_[0]};
	my @ref_arr = @{$ref{val}};
    my $theVal = $_[1];
    my $counter = 0;
    for(my $i =0;$i<(scalar @ref_arr);$i++){
        if($theVal> $ref_arr[$i]){
            $counter++;
        }
    }
    my $oot;
    if($_[2]){
        $oot = $counter/($ref{cnt}-1);   #-1 to not count self
    }
    else{
        $oot = $counter/($ref{cnt});   #-1 to not count self

    }
    $oot = $oot*100;                    #get percent
    return int($oot);
}
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
    my $perc = percentile($_[0],$dat[0],1);
	
	print "\t\t". $dat[0] . " ($perc%) " . $dat[1] ." - ".$presPos. "\n";
	
}
sub scraper {
	my $usrn = $_[0];
	my $pswd = $_[1];
	my $week = $_[2];
    my $url = "http://fantasy.nfl.com/league/" .$_[3];
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
	@teamNames = ();
	foreach my $tm(@tmpNames){
		#print "Comparing " . $tm ."\n";
		if(length($tm)>0){
			#print "Pushing " . $tm . "\n";
			push(@teamNames, $tm);
		}
	}
	my $numTeams = (scalar @teamNames);
	my $dir1 = "week".$week;
	mkdir $dir1;
	my $dir = dir($dir1);
	print "Parsing Teams:\n";
	for(my $j = 1; $j<=$numTeams; $j++){
		print $teamNames[$j-1]."($j)";
		$mech->get($tUrl . $j."?week=".$week);
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
            my $k = 1;
            if(length($ts->cell(2,1))<10){
                $k = 3;
            }
			if($ts->count==0){
				if($j==5){
					my @info = split / -/, $ts->cell(2,$k);
					$disTeam{"QB"} = [$ts->cell(2,-1), trim($info[0])];
					@info = split / -/, $ts->cell(3,$k);
					$disTeam{"RB1"} = [$ts->cell(3,-1), trim($info[0])];
					@info = split / -/, $ts->cell(4,$k);
					$disTeam{"RB2"} = [$ts->cell(4,-1), trim($info[0])];
					@info = split / -/, $ts->cell(5,$k);
					$disTeam{"WR1"} = [$ts->cell(5,-1), trim($info[0])];
					@info = split / -/, $ts->cell(6,$k);
					$disTeam{"WR2"} = [$ts->cell(6,-1), trim($info[0])];
					@info = split / -/, $ts->cell(7,$k);
					$disTeam{"TE"} = [$ts->cell(7,-1), trim($info[0])];
					@info = split / -/, $ts->cell(8,$k);
					$disTeam{"W/R"} = [$ts->cell(8,-1), trim($info[0])];
					#Skip 9 for "Bench" row
					for(my $i=10; $i<$lim; $i++){
						@info = split / -/, $ts->cell($i,$k);
						$disTeam{"BN".($i-9)} = [$ts->cell($i,-1), trim($info[0])];
					
					}
					
				}else{
					my @info = split / -/, $ts->cell(2,2);
					$disTeam{"QB"} = [$ts->cell(2,-1), trim($info[0])];
					@info = split / -/, $ts->cell(3,2);
					$disTeam{"RB1"} = [$ts->cell(3,-1), trim($info[0])];
					@info = split / -/, $ts->cell(4,2);
					$disTeam{"RB2"} = [$ts->cell(4,-1), trim($info[0])];
					@info = split / -/, $ts->cell(5,2);
					$disTeam{"WR1"} = [$ts->cell(5,-1), trim($info[0])];
					@info = split / -/, $ts->cell(6,2);
					$disTeam{"WR2"} = [$ts->cell(6,-1), trim($info[0])];
					@info = split / -/, $ts->cell(7,2);
					$disTeam{"TE"} = [$ts->cell(7,-1), trim($info[0])];
					@info = split / -/, $ts->cell(8,2);
					$disTeam{"W/R"} = [$ts->cell(8,-1), trim($info[0])];
					#Skip 9 for "Bench" row
					for(my $i=10; $i<$lim; $i++){
						@info = split / -/, $ts->cell($i,2);
						$disTeam{"BN".($i-9)} = [$ts->cell($i,-1), trim($info[0])];
					
					}
				}
			}
			if($ts->count==1){
				if($j==5){
					my @info = split / -/, $ts->cell(2,$k);
					$disTeam{"K"} = [$ts->cell(2,-1), trim($info[0])];
				}else{
					my @info = split / -/, $ts->cell(2,2);
					$disTeam{"K"} = [$ts->cell(2,-1), trim($info[0])];	
				}
			}
			if($ts->count==2){
				if($j==5){
					my @info = split /-/, $ts->cell(2,$k);
					$disTeam{"DEF"} = [$ts->cell(2,-1), trim($info[0])];
				}else{
					my @info = split /-/, $ts->cell(2,2);
					$disTeam{"DEF"} = [$ts->cell(2,-1), trim($info[0])];	
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

    print "Parsing Free Agents:\n";
    %frees = ();
    my $statPos ="players?playerStatus=available&position=";
    my $wkSeason ="&statCategory=stats&statSeason=2012&statType=weekStats&statWeek=";
    my $front = '.*<div class="tableWrap.*>(.*)</div>.*';
    for(my $i=1; $i<5; $i++){
        $mech->get($url."/".$statPos.$i.$wkSeason.$week);
        my $te = HTML::TableExtract->new();
        my $html = $mech->content;
        $te->parse($html);
        print getPos($i);
        my @players = ();
        foreach my $ts ($te->tables) {
            print ".";
            foreach my $row ($ts->rows) {
                my @row1 = @{$row};
                if($row1[-1]>0){
                    my @dat = split /-/, $row1[1];
                    my $player = trim($dat[0]);
                    my @ret = ($row1[-1],$player);
                    push(@players, \@ret);
                }
            }
            print ".";
        }
        print ".";
        $frees{getPos($i)}=\@players;
        my $json = JSON->new->allow_nonref;
		my $json_text   = $json->encode(\@players);
		my $file = $dir->file("free". $i .".txt");
		my $file_handle = $file->openw();
		$file_handle->print($json_text);
        print ".";
        print "done!\n";
    }
    for(my $i=7; $i<9; $i++){
        $mech->get($url."/".$statPos.$i.$wkSeason.$week);
        my $te = HTML::TableExtract->new();
        my $html = $mech->content;
        $te->parse($html);
        print getPos($i);
        my @players = ();
        foreach my $ts ($te->tables) {
            print ".";
            foreach my $row ($ts->rows) {
                my @row1 = @{$row};
                if($row1[-1]>0){
                    my @dat = split /-/, $row1[1];
                    my $player = trim($dat[0]);
                    my @ret = ($row1[-1],$player);
                    push(@players, \@ret);
                }
            }
            print ".";
        }
        print ".";
        $frees{getPos($i)}=\@players;
        my $json = JSON->new->allow_nonref;
		my $json_text   = $json->encode(\@players);
		my $file = $dir->file("free". $i .".txt");
		my $file_handle = $file->openw();
		$file_handle->print($json_text);
        print ".done!\n";
    }
    
}
sub getPos{
    switch($_[0]){
        case 1 {return "QB"}
        case 2 {return "RB"}
        case 3 {return "WR"}
        case 4 {return "TE"}
        case 7 {return "K"}
        case 8 {return "DEF"}
        else {return "OTHER"}
    }
}
sub trim($){           #trims trailing whitespace
	my $string = shift;
	$string =~ s/\s+$//;
	return $string;
}
sub scrape{
	my $week = $_[0];
	if($week == 0){
		$week = checkWeek();
	}
	my $league = prompt("Please enter your league number: ");
	my $usrn = prompt("Username: " );
	my $pswd = prompt("Password: ", -e => '*');
	scraper($usrn,$pswd,$week,$league);
}
sub analyzer{
	my $teamNum = $_[0];
	my $weekNum = $_[1];
	#calc num of teams
	my $dir = dir("week" . $weekNum);
	
	#for stats
	
	%myTeam = {};
	
	#print "LINE 29\n";							#DEBUG
	@teams = ();						#array of hash references
	my $json = JSON->new->allow_nonref;
	my $herp = scalar @teamNames;
	if($herp == 0){
		print "Can not access team files, have you run Scraper?\n";
		return;
	}
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
    
	my $dir = dir("week" . $weekNum, "stats");
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
    %frees = ();
    my $dir = dir("week" . $weekNum);
    for(my $x=1;$x<9;$x++){
		my $file = $dir->file("free".$x.".txt");
		my $str = $file->slurp();
        #print "free$x.txt:\n$str\n";
        $frees{getPos($x)} = $json->decode( $str );
        if($x==4){
            $x=6;
        }
    }
    #print Dumper \%frees;
    my $bench = prompt "Show bench? (y/n) ", -yn;
    foreach my $key (keys %myTeam){
        if($bench or substr($key,0,2) ne "BN"){
            my @data = @{$myTeam{$key}};
            my @info = split / /, $data[1];
            my $pos = $info[-1];
            switch($pos){
                case "QB"	{freeComp(0,\@data)}
                case "RB"	{freeComp(1,\@data)}
                case "WR"   {freeComp(2,\@data)}
                case "TE"	{freeComp(3,\@data)}
                case "K"	{freeComp(4,\@data)}
                case "DEF"	{freeComp(5,\@data)}
                else		{print $pos . " is invalid!\n"}
            }
        }
    }
}
sub analyze{
	my $week = $_[0];
	if($week == 0){
		$week = checkWeek();
	}
    $theWeek = $week;
	my $dir = dir("week" . $week);
	my $json = JSON->new->allow_nonref;
	my $file1 = $dir->file("hash.txt");
	my $str1 = $file1->slurp();
	@teamNames = @{$json->decode( $str1 )};
	for(my $i=0; $i<(scalar @teamNames); $i++){
		#print ($i+1) . ". ".$teams[$i];
		print "\t\t ". ($i+1). ") " . $teamNames[$i]."\n";
	}
	my $team = prompt("Choose your team: ");
	$team-=1;
	$myTeamNum = $team;
	analyzer($team,$week);
}
sub run{
	my $week = checkWeek();
	scrape($week);
	analyze($week);
}
sub getPlayer{
	my $p1 = $_[0];
	my @res1 = ();
	my $comp1;
	my $len  = scalar @teams;
	for(my $i=0;$i<$len ;$i++){
		my %team = %{$teams[$i]};
		for my $key (keys %team) {
			my @data = @{$team{$key}};
			my @info = split / /, $data[1];
			my $pos = $info[-1];
			my $dist1 = distance($p1, $info[0]." ".$info[1]);
			if($dist1<(length($p1)/2)){
				#print $info[0]." ".$info[1]." is only $dist1 off of $p1!\n";
				push(@data, $i);
				push(@res1, \@data);
			}
		}
	}
	if(scalar @res1 == 0){
		print "No results found for $p1.\n";
	}elsif(scalar @res1 == 1){
		$comp1 = $res1[0];
	}else{
		my $x = 1;
		foreach(@res1){
			my @temp = @{$_};
			print "$x) ".$temp[1]."\n";
			$x++;
		}
		my $choi = prompt "Choose Result: ";
		$comp1 = $res1[$choi-1];
	}
	return $comp1;
}
sub comp{
	my @p1 = @{getPlayer($_[0])};
	#print "Got ".$p1[1]."\n";
	my @p2 = @{getPlayer($_[1])};
    print $teamNames[$p1[2]]." owns ".$p1[1]." : ".$p1[0]."\n";
	print $teamNames[$p2[2]]." owns ".$p2[1]." : ".$p2[0]."\n"; 
	#print "Got ".$p2[1]."\n";
	
}
sub teamScore{
    my %theTeam = %{$teams[$_[0]]};
    my $tScore+= $theTeam{QB}[0]+$theTeam{RB1}[0]+$theTeam{RB2}[0]+$theTeam{WR1}[0]+$theTeam{WR2}[0]+$theTeam{TE}[0]+$theTeam{"W/R"}[0]+$theTeam{K}[0]+$theTeam{DEF}[0];
    return $tScore;
	
}
sub scores{
    print "\t\tScores for Week $theWeek\n";
    print "\t\t====================\n";
    my %stands = ();
    for(my $x = 0; $x<(scalar @teamNames); $x++){
        $stands{$teamNames[$x]} = teamScore($x);
        #print "$teamNames[$x] scored ".teamScore($x)." points.\n";
    }
    foreach my $fruit (sort {$stands{$b} <=> $stands{$a}} keys %stands) {
        print  "\t\t".$stands{$fruit} . " - " . $fruit  ."\n";
    }
}
print "\t#########################################\n";
print "\t#\tFantasyFiend v0.4\t\t#\n";
print "\t#\tBy: James Watterson\t\t#\n";
print "\t#########################################\n\t\tuse h, help, or ? for usage\n";
my @choices = ("scrape", "analyze", "stats", "team", "quit", "run", "compare", "scores");
@choices = sort @choices;
while(prompt -prompt =>"=>", -complete => \@choices){
	my $in = $_;
	my @spli = split / /, $in;
	if(length($in)>0){
		if ($in eq "quit" || $in eq "q"){
			last;
		}elsif ($in eq "scores"){
            if(keys %myTeam){
				scores();
			}
			else{
				print "No teams in memomry, running analysis....\n";
				analyze();
				scores();
			}
        }
		elsif (substr($in,0,4) eq "lyze" || substr($in,0,7) eq "analyze"){
			analyze($spli[1]);
		}
		elsif ($in eq "scrape" || $in eq "scrap"){
			scrape();
		}
		elsif ($in eq "h" || $in eq "help" || $in eq "?"){
			help();
		}
		elsif ($in eq "stats" || $in eq "stat"){
			printStats();
		}
		elsif ($spli[0] eq "t" || $spli[0] eq "team"){
			if(keys %myTeam){
				if(scalar @spli==2){
					if($spli[1]>0 && $spli[1]<=(scalar @teams)){
						printTeam($spli[1]-1);
					}else{
						print "Team $spli[1] does not exist\n";
					}
				}else{
					printTeam($myTeamNum);
				}
			}
			else{
				print "No team specified, running analysis....\n";
				analyze();
				if(scalar @spli==2){
					if($spli[1]>0 && $spli[1]<(scalar @teams)){
						printTeam($spli[1]-1);
					}else{
						print "Team $spli[1] does not exist\n";
					}
				}else{
					printTeam($myTeamNum);
				}
			}
		}
		elsif ($in eq "r" || $in eq "run"){
			run();
		}
        elsif ($spli[0] eq "eval"){
			my $cmd = substr($in, 4);
            print "evaling: $cmd\n";
            my $res = eval $cmd;
            print $res."\n";
		}
        elsif($in eq "shell"){
            print "**WARNING**\nYou are now entering the perl shell, type 'return' to exit\n";
            while(prompt -prompt =>"\$"){
                my $cmd = $_;
                if($cmd eq "return"){
                    last;
                }
                else{
                    my $ret = eval $cmd;
                    if(length($ret>0)){
                        print "$ret\n";
                    }
                }
            }
        }
		elsif ($spli[0] eq "c" || $spli[0] eq "comp" || $spli[0] eq "compare"){
			#print (scalar @spli)."\n";
			if((scalar @teams)>0){
				if((scalar @spli) == 5){
					comp($spli[1]." ".$spli[2], $spli[3]." ".$spli[4]);
				}else{
					print "Invalid Args, do:\ncomp first1 last1 first2 last2\n";
				}
			}else{
				print "Teams array is empty, run analyzer.\n"
			}
		}
		else{
			print "command: '$spli[0]' not recognized\n";
		}
	}
}