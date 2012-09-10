use PDL::Graphics::Prima::Simple;
use PDL;


# --( Super simple line and symbol plots )--

# Generate some data - a sine curve
my $x = sequence(100) / 10;
my $y = sin($x);

my $colors = pal::Rainbow()->apply($x);
plot(
-lines         => ds::Pair($x, $y
, plotType => ppair::Lines
),
-color_squares => ds::Pair($x, $y + 1
, colors   => $colors,
, plotType => ppair::Squares(filled => 0)
),

x => { label   => 'Time' },
y => { label   => 'Sine' },
);