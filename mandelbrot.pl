#!/usr/bin/perl -w
use strict;

use POSIX qw(floor);
use Term::ReadKey;
use Getopt::Long;
use Math::BigFloat;

# spiral
# ./mandelbrot.pl -x -.7435669 -y .1314023 -w .003

my %palette = (
  grayscale256 => [ map { ["\e[48;5;${_}m"," "] } (0, 232..255, 15) ],
  rainbow256 => [ map { ["\e[48;5;${_}m"," "] } (16, 52,88,124,160,196, 202,208,214,220,226, 190,154,118,82,46, 47,48,49,50,51, 45,39,33,27,21, 57,93,129,165,201, 207,213,219,225,231) ],
  rainbow16 => [ map { ["\e[4${_}m"," "] } qw(0 1 3 2 4 6 5 7) ],
  ascii => [ map { ["",$_] } (' ', qw(. - + = * & @), '#') ],
);

my %opt = (
  x => -.7,
  y => 0,
  w => 3,
  p => 'ascii',
  d => 200,
  i => 0,
  q => 0,
  v => 0,
  lines => 0,
  cols => 0,
  help => 0,
);
GetOptions(\%opt, 'x=f', 'y=f', 'w=f', 'p=s', 'd=i', 'i', 'v', 'lines=i', 'cols=i', 'q', 'help|h|?');

if ($opt{help}) {
  print <<EOF;
Usage: ./mandelbrot.pl [<opt>...]
Interactively explore the mandelbrot set right from your terminal.

  -x   Set the x coordinate of the center of the view. (Default -.7)
  -y   Set the y coordinate of the center of the view. (Default 0)
  -w   Set the width of the view. (Default 3; the height is calculated
       automatically from the terminal's aspect ratio.)
  -p   Choose the palette to draw the fractal.
  -d   Set the max depth for per-pixel iteration. (Default 200)
  -i   Show the current location / depth information.
  -q   Quit after rendering (do not go into interactive mode).
  -v   Invert the palette.

  --lines  Force output to the given number of lines rather than using the
           terminal dimensions.
  --cols   As above, but for columns.
  --help   Display this help.

Available palettes are: @{[join(", ", sort keys %palette)]}

Keys available once the program is started:
y k u  Move the center of the view laterally or diagonally.  Capital letters
h   l  will move the view 5x faster.
b j n

  <,>  Zoom out / in by a factor of 2x.
  +,-  Increase / decrease the max iteration depth by a factor of 2x.
  i    Toggle display of the current location / depth.
  v    Toggle palette inversion.
  ;    Select a new view center with the cursor; use the move keys above to
       move the cursor and '.' to choose the position under the cursor.
  1,2  Switch to the C (1) or Perl (2) mandelbrot function.  Useful for
       debugging or to demonstrate the difference in speed.
  q    Quit. (You can also use ^C or SIGINT.)
EOF
  exit;
}

my ($xc, $yc, $iw, $maxdepth, $showinfo, $invert) = @opt{qw(x y w d i v)};

die "invalid palette (-p); valid options are " . join(", ", sort keys %palette) . "\n" unless $palette{$opt{p}};
my @palette = @{$palette{$opt{p}}};

my $patfit = @palette < 30;

my @move = (
  ['y', 'k', 'u'],
  ['h', '',  'l'],
  ['b', 'j', 'n'],
);

my %movekey;
for my $m_yi (0..2) {
  for my $m_xi (0..2) {
    my $k = $move[$m_yi][$m_xi];
    next unless length $k == 1;
    my $mx = $m_xi - 1;
    my $my = $m_yi - 1;
    next unless $mx || $my;
    $movekey{lc $k} = [1*$mx, 1*$my];
    $movekey{uc $k} = [5*$mx, 5*$my];
  }
}

chomp(my $termw = $opt{cols}  || `tput cols` );
chomp(my $termh = $opt{lines} || `tput lines`);

sub quit {
  print loc($termh,1)."\n" unless $opt{q};
  ReadMode(0);
  exit;
}
$SIG{INT} = \&quit;

ReadMode(3);

my ($xl, $xh, $yl, $yh);
*mb_depth = \&mb_depth_c;

while (1) {
  my $ih = ($iw / $termw * $termh * 2);
  ($xl, $xh, $yl, $yh) = ($xc-$iw/2, $xc+$iw/2, $yc-$ih/2, $yc+$ih/2);

  render();
  quit() if $opt{q};
  print loc($termh,$termw);

  while (1) {
    my $k = ReadKey(0);
    if ($k eq 'q') {
      quit();
    } elsif ($k eq '<') {
      $iw *= 2;
    } elsif ($k eq '>') {
      $iw *= .5;
    } elsif ($k eq '+') {
      $maxdepth *= 2;
    } elsif ($k eq '-') {
      $maxdepth = max(10, int($maxdepth * .5));
    } elsif ($k eq 'i') {
      $showinfo = !$showinfo;
    } elsif ($k eq 'v') {
      $invert = !$invert;
    } elsif ($k eq ';') {
      ($xc, $yc) = choosexy();
    } elsif ($k eq '1') {
      do { no warnings 'redefine'; *mb_depth = \&mb_depth_c; }
    } elsif ($k eq '2') {
      do { no warnings 'redefine'; *mb_depth = \&mb_depth_perl; }
    } elsif ($movekey{$k}) {
      $xc += .1*$iw*$movekey{$k}[0];
      $yc -= .1*$ih*$movekey{$k}[1];
    } else {
      next;
    }
    last;
  }
}

sub choosexy {
  my ($r, $c) = map {int} ($termh/2, $termw/2);

  while (1) {
    print loc($r, $c);
    my $k = ReadKey(0);
    if ($movekey{$k}) {
      $r += $movekey{$k}[1];
      $c += $movekey{$k}[0];
    } elsif ($k eq '.') {
      return (c2x($c), r2y($r));
    }
  }
}

sub render {
  my @depth;

  my ($min, $max) = (1, 0);
  my $xe = (c2x(2) - c2x(1))/4;
  my $ye = (r2y(2) - r2y(1))/4;
  my $tot_px = $termh*$termw;
  my $num_px = 0;

  local $| = 1;

  my @info = (
    "x:" . (new Math::BigFloat($xc)),
    "y:" . (new Math::BigFloat($yc)),
    "w:" . (new Math::BigFloat($iw)),
    "d:" . $maxdepth,
  );
  @info = map { "$_ " } @info if $palette[0][0] eq '';

  print "\e[0;40m".loc(1,1) unless $opt{q};

  for my $r (1..$termh) {
    printf "\r%d%%", $num_px/$tot_px*100 unless $opt{q};

    my $firstcol = $showinfo && $r <= @info ? length($info[$r-1])+1 : 1;

    my $y = r2y($r);
    for my $c ($firstcol..$termw) {
      my $x = c2x($c);

      my $d0 = mb_depth($x    , $y    , $maxdepth);
      my $d1 = mb_depth($x+$xe, $y    , $maxdepth);
      my $d2 = mb_depth($x-$xe, $y    , $maxdepth);
      my $d3 = mb_depth($x    , $y+$ye, $maxdepth);
      my $d4 = mb_depth($x    , $y-$ye, $maxdepth);
      my $d = ($d0+$d1+$d2+$d3+$d4)/5;

      $depth[$r][$c] = $d;
      if ($patfit) {
        $min = $d if $d < $min;
        $max = $d if $d > $max;
      }

      $num_px++;
    }
  }

  if ($patfit) {
    $max = $min+1 if $max == $min;
    ($min, $max) = ($max, $min) unless $invert; #because patterns are backwards
  } else {
    ($min, $max) = ($max, $min) if $invert;
  }

  my $buffer = "";
  my $lastpali = -1;
  $buffer .= "\e[0m" . loc(1,1) unless $opt{q};
  for my $r (1..$termh) {
    my $firstcol = 1;
    if ($showinfo && $r <= @info) {
      my $info = $info[$r-1];
      $buffer .= "\e[0;40m$info";
      $firstcol = length($info)+1;
    }

    for my $c ($firstcol..$termw) {
      my $pali = interpolate($depth[$r][$c],$min,$max,0,$#palette);
      $buffer .= $palette[$pali][0] if $pali != $lastpali;
      $lastpali = $pali;
      $buffer .= $palette[$pali][1];
    }
    $buffer .= "\n" if $r < $termh || $opt{lines};
  }
  print $buffer;
}

sub mb_depth_perl {
  my ($x0, $y0, $mi) = @_;
  my ($x, $y, $i) = ($x0, $y0, 0);
  while ($x*$x + $y*$y < 2*2 && $i < $mi) {
    ($x, $y) = ($x*$x - $y*$y + $x0, 2*$x*$y + $y0);
    $i++;
  }
  return $i/$mi;
}

use Inline C => <<'END';
float mb_depth_c(double x0, double y0, int mi) {
  double x = x0;
  double y = y0;
  int i = 0;
  while (x*x + y*y < 2*2 && i < mi) {
    double xtemp = x*x - y*y + x0;
    y = 2*x*y + y0;
    x = xtemp;
    i++;
  }
  return ((float)i)/mi;
}
END

sub interpolate {
  my ($v, $il, $ih, $ol, $oh) = @_;
  return ($v - $il) / ($ih - $il) * ($oh - $ol) + $ol;
}
sub c2x { interpolate($_[0]+.5, 1, $termw, $xl, $xh) }
sub r2y { interpolate($_[0]+.5, 1, $termh, $yh, $yl) }
sub x2c { floor(-.5+interpolate($_[0], $xl, $xh, 1, $termw)) }
sub y2r { floor(-.5+interpolate($_[0], $yh, $yl, 1, $termh)) }
sub loc { "\e[$_[0];$_[1]H" }
sub min { $_[0] < $_[1] ? $_[0] : $_[1] }
sub max { $_[0] > $_[1] ? $_[0] : $_[1] }
