use WWW::Mechanize;
use strict;
use Data::Dumper;
use HTML::TableExtract;

my $usrn = "usr";
my $pswd = "pass";
my $week = 1;
my $url = "http://fantasy.nfl.com/league/1012931";
my $mech = WWW::Mechanize->new();
$mech->get($url);
$mech->submit_form(
        form_number => 1,
        fields      => {
            username    => $usrn,
            password    => $pswd,
        }
);
my $pos = 1;
my $week = 1;
my $statPos ="players?playerStatus=available&position=";
my $wkSeason ="&statCategory=stats&statSeason=2012&statType=weekStats&statWeek=";
my $front = '.*<div class="tableWrap.*>(.*)</div>.*';
for(my $i=1; $i<5; $i++){
    $mech->get($url."/".$statPos.$i.$wkSeason.$week);
    my $te = HTML::TableExtract->new();
    my $html = $mech->content;
    $te->parse($html);
    foreach my $ts ($te->tables) {
        print "Table (", join(',', $ts->coords), "):\n";
        foreach my $row ($ts->rows) {
            my @row1 = @{$row};
            if($row1[-1]>0){
                my @dat = split /-/, $row1[1];
                print  $dat[0]." - ".$row1[-1]."\n";
            }
        }
    }
    print "===============\n";
}