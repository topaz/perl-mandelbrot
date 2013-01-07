This repo contains an interactive Mandelbrot set renderer and explorer for use in ASCII-only, 16-color, and 256-color terminals.  For usage instructions, run `./mandelbrot.pl -?`, or see below.  Requires [Inline::C](http://search.cpan.org/perldoc?Inline::C).

```
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

Available palettes are: ascii, grayscale256, rainbow16, rainbow256

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
```

```
$ ./mandelbrot.pl -x -.7435669 -y .1314023 -w .003 -q --lines=24 --cols=80 -v -d 600
                                                                                
                                       +-      .-                               
                              -.      -+-.+-. .---                              
                              ++=...  .-+-.-  -==+.--  -..                      
                    ....  .....+=--...+.--.....+++-.  +&+                       
                    +=--+--.. +.-.+-..---+=+..+-+....-+---.                     
                      +++-++ .-..--+*.    -.   -=.-.---.*+ .    .               
             .    --   --+.-.--                     +&..*-+=*#+.+               
            .  .....+  .. .--+--                     - +-.--++.                 
            --*&=+.-  .---.-                           +*-.-.-.=                
             ----+.--.-.-                    .          .+.+-                   
        ... .  .....=-+*+-               -.---..-.       ---++=*+..             
  -    . -.    --.. .--                 +-.. ...=.     ==+---+=- .+             
++.   ......-....-=+..                  .-.   -.        +.-.=..                 
- .--+=+*-...  -..                     .+==.          =+-..= .-                 
 ..-+*=++-.=.  .-.-+-                    .+-*-.-  --..+..-+=*=.                 
   ..-.-+--.-..-+**-+-                    &=--.-..-.-++.=--- .+                 
 ..   . ..   .-.--- .                       .-==- ++-=+-. .                     
.       *...  --.-                           -.-  .  .--                        
++        +.---...                                   -                          
.+ -+....--&.+-                                                                 
-  .-.--  .-.                                                                   
----..   -..-   .                                                               
```
