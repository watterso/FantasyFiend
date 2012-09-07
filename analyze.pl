use Data::Dumper;
use strict;
use Path::Class;
use Path::Class::Dir;
use List::Util qw(sum);

@ARGV or die "Usage: $0 team week\n";

my $teamNum = $ARGV[0];
my $weekNum = $ARGV[1];

#calc num of teams
my $dir = dir("week" . $weekNum);
my $nfiles = $dir->traverse(sub {
    my ($child, $cont) = @_;
    return sum($cont->(), ($child->is_dir ? 0 : 1));
  });
$nfiles--;	#offset for hash file;

my $file = $dir->file("team1.txt");
my $str = $file->slurp();
my $VAR1;
eval $str;
print Dumper $VAR1;