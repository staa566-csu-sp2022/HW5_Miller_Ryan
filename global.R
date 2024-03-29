## Load required libraries
library(   hdf5r   )
library(  plotly   )
library(  pracma   )
library(    psd    )
library( rsconnect )
library(  signal   )
library( tidyverse )

## Libraries required for shiny
library( shiny )
library( shinydashboard )

#########################################################################################
## Data Processing
#########################################################################################
## Get strain data from H1 detector
h1.file.loc  <- 'https://losc.ligo.org/s/events/GW150914/H-H1_LOSC_4_V1-1126259446-32.hdf5'
h1.temp.file <- tempfile( fileext = '.hdf5' )
download.file( h1.file.loc, h1.temp.file )
h1.5    <- hdf5r::H5File$new( h1.temp.file, mode = 'r+' )
file.remove( h1.temp.file );
rm( list = c('h1.file.loc', 'h1.temp.file' ) )

## Get strain data from L1 detector
l1.file.loc  <- 'https://losc.ligo.org/s/events/GW150914/L-L1_LOSC_4_V1-1126259446-32.hdf5'
l1.temp.file <- tempfile( fileext = '.hdf5' )
download.file( l1.file.loc, l1.temp.file )
l1.5    <- hdf5r::H5File$new( l1.temp.file, mode = 'r+' )
file.remove( l1.temp.file );
rm( list = c('l1.file.loc', 'l1.temp.file' ) )

## Get numeric relativity template
nrel <- read_table( 'https://losc.ligo.org/s/events/GW150914/GW150914_4_NR_waveform.txt',
                   col_names = FALSE )

## Generate a time vector (in this data we know that H1 L1 are the same)
dt        <- h5attr( h1.5[['/strain/Strain']], 'Xspacing' )
gps.start <- h1.5[['/meta/GPSstart']][]
gps.end   <- gps.start + length( h1.5[['/quality/injections/Injmask']][] )
time      <- seq( from = gps.start, to = gps.end, by = dt )
dt2       <- time[2] - time[1]; if( dt != dt2 ){ dt = dt2 }

## Get the strain values for both detectors
strain.h1 <- h1.5[['/strain/Strain']][]
strain.l1 <- l1.5[['/strain/Strain']][]
strain.nr <- nrel$X2
time.nr   <- nrel$X1

## Raw signal plot
t.event <- 1126259462.422
t.off   <- 5
idx     <- which( time >= t.event - t.off & time < t.event + t.off )
idx     <- which( time >= t.event - 0.10 & time < t.event + 0.05 )
t.nr    <- time.nr+0.002
idx.nr  <- which( time.nr >= -0.10 & time.nr < 0.05 );

## Set up the plotly functions
pd.raw <- data.frame( Time = time[ idx ] - t.event,
                     L1 = strain.l1[ idx ], H1 = strain.h1[ idx ] )
h.raw <- plot_ly( pd.raw, x = ~Time ) %>%
    add_lines( y = ~L1, name = 'L1' ) %>%
    add_lines( y = ~H1, name = 'H1' ) %>% rangeslider() %>% layout( hovermode = 'x' ) %>%
    layout( title = 'LIGO Raw Strain Near GW150914',
           xaxis = list( title = 'Time (s) since GW150914' ),
           yaxis = list( title = 'Strain' ) )

## Get spectral densities
fs     <- 4096 # Sampling frequency
psd.h1 <- psd::pspectrum( strain.h1, x.frqsamp = fs )
psd.l1 <- psd::pspectrum( strain.l1, x.frqsamp = fs )

## Whiten the signal
if( ! ( length( strain.h1 ) - length( strain.l1 ) ) )
{
    # Will error out after this if N is undefined; i.e., the lengths are different
    N    <- length( strain.h1 )
    EVEN <- !psd::mod( N, 2 )
}

if( EVEN )
# Even
{
    pos.freqs <- seq( from = 0, to = ( N / 2 ) - 1, by = 1 ) / ( dt * N )
    neg.freqs <- seq( from = -N/2, to = -1, by = 1 ) / ( dt * N )
} else
# Odd
{
    pos.freqs <- seq( from = 0, to = (N-1) / 2, by = 1 ) / ( dt * N )
    neg.freqs <- seq( from = -(N-1) / 2, to = -1, by = 1 ) / ( dt * N )
}
freqs      <- c( pos.freqs, neg.freqs )

## Whiten H1
div        <-  sqrt( pracma::interp1( psd.h1$freq, psd.h1$spec, abs(freqs) ) / dt / 2 )
white.h1.f <- fft( strain.h1 ) / div
white.h1   <- Re( fft( white.h1.f, inverse = TRUE ) / N )

## Whiten L1
div        <-  sqrt( pracma::interp1( psd.l1$freq, psd.l1$spec, abs(freqs) ) / dt / 2 )
white.l1.f <- fft( strain.l1 ) / div
white.l1   <- Re( fft( white.l1.f, inverse = TRUE ) / N )

## Also have to do this for the relativistic model
n.nr       <- length( strain.nr ) # [1] 2769 <== Odd
p.freq     <- seq( from = 0, to = (n.nr-1) / 2, by = 1 ) / ( dt * n.nr )
n.freq     <- seq( from = -(n.nr-1) / 2, to = -1, by = 1 ) / ( dt * n.nr )
freq       <- c( p.freq, n.freq )
div        <-  sqrt( pracma::interp1( psd.h1$freq, psd.h1$spec, abs(freq) ) / dt / 2 )
white.nr.f <- fft( strain.nr ) / div
white.nr   <- Re( fft( white.nr.f, inverse = TRUE ) / n.nr )

# Shift by mean so they are both around zero, something. This is normally
# handled by the whitening process with Real-FFT's, which are not implemented in R.
white.h1 <- white.h1 - mean( white.h1 )
white.l1 <- white.l1 - mean( white.l1 )
white.nr <- white.nr - mean( white.nr )

## Plot the whitened signal
pd.white <- data.frame( Time = time[ idx ] - t.event,
                       L1 = white.l1[ idx ], H1 = white.h1[ idx ] )
h.white <- plot_ly( pd.white, x = ~Time ) %>%
    add_lines( y = ~L1, name = 'L1' ) %>%
    add_lines( y = ~H1, name = 'H1' ) %>% rangeslider() %>% layout( hovermode = 'x' ) %>%
    layout( title = 'LIGO Whitened Strain Near GW150914',
           xaxis = list( title = 'Time (s) since GW150914' ),
           yaxis = list( title = 'Whitened Strain' ) )

## Bandpass the data to remove the high frequency noise
filt.coef  <- signal::butter( n = 4, W = c( 20 * 2 / fs, 300 * 2 / fs ), type = 'pass' )
whitebp.h1 <- signal::filtfilt( filt.coef, white.h1 )
whitebp.l1 <- signal::filtfilt( filt.coef, white.l1 )
whitebp.nr <- signal::filtfilt( filt.coef, white.nr )

## Invert and shift L1 sensor by 0.007
shift    <- as.integer( 0.007 * fs )
shift.l1 <- -c( tail( whitebp.l1, shift ), head( whitebp.l1, -shift ) )

## Plot the final signals
pd.whitebp <- data.frame( Time = time[ idx ] - t.event,
                         L1 = shift.l1[ idx ], H1 = whitebp.h1[ idx ] )
pd.nr <- data.frame( Time = t.nr[ idx.nr ], NR = whitebp.nr[ idx.nr ] )
h.whitebp <- plot_ly( pd.whitebp, x = ~Time ) %>%
    add_lines( y = ~L1, name = 'L1' ) %>%
    add_lines( y = ~H1, name = 'H1' ) %>%
    add_lines( data = pd.nr, x = ~Time, y = ~NR, opacity = 0.6, name = 'NR' ) %>%
    rangeslider() %>% layout( hovermode = 'x' ) %>%
    layout( title = 'LIGO Whitened+Filtered Strain Near GW150914',
           xaxis = list( title = 'Time (s) since GW150914' , range = c(-0.10, 0.05)),
           yaxis = list( title = 'Whitened+Filtered Strain' ) )
