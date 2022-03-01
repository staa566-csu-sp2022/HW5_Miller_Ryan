dashboardPage(
    ## Format the page
    skin = 'green',

    ## Title/Header
    dashboardHeader(
        title = 'Gravity Waves!'
    ),

    ## Sidebar
    dashboardSidebar(
        sidebarMenu(
            menuItem( 'Main'           , tabName = 'main' ),
            menuItem( 'Raw Signal'     , tabName = 'raw_sig' ),
            menuItem( 'Whitened Signal', tabName = 'white_sig' ),
            menuItem( 'Final Signal'   , tabName = 'final_sig' )
        )
    ),

    ## Body
    dashboardBody(
        tabItems(
            tabItem( 'main',
                    h1( 'Gravity Waves' ),
                    p("This shiny project presents the data from the first observed
                      gravitational wave, known as `GW150914`, which took place in
                      September 2015 and was produced by the merging of two black holes.
                      The signal processing process is presented step-by-step via the
                      dashboard/menu items."),
                    p("Data is shown from each of the two detectors `L1`
                      (Livingston) and `H1` (Hanford) as well as from a theoretical
                      numerical relativity model."),
                    p("I chose this data for several reasons. First, it is in HDF5 format,
                      which I had never used in R before. Second, it required some signal
                      processing which I had also never done in R before. Third, I enjoy
                      Physics and I thought this was a cool project; it was challenging to
                      get the data in and processed in R, and gave me a chance to learn
                      new skills."),
                    h2( 'References' ),
                    p('[1] A guide to LIGO-Virgo detector noise and extraction of transient gravitational-wave
                    signals; https://arxiv.org/pdf/1908.11170.pdf'),
                    p('[2] Signal Processing with GW150914 Open Data;
                    https://www.gw-openscience.org/GW150914data/GW150914_tutorial.html')
            ),
            tabItem( 'raw_sig',
                    h2( 'Raw Signal' ),
                    p("In the first figure we can see the raw strain signal from each of
                      the detection sites. There is obvious low frequency content in the
                      signals that are causing the means to be offset from one another.
                      According to [2], we can ignore this low frequency content in
                      analysis. The signal is contained in the higher frequencies, so we
                      need to do a bit of signal processing on the data."),
                    box( plotlyOutput('p_raw'), width = '500' ),
                    box( dataTableOutput( 't_raw' ), width = '500' )
            ),
            tabItem( 'white_sig',
                    h2( 'Whitened Signal' ),
                    p("The first step is to whiten the data to suppress noise. According
                      to [2], 'Whitening is always one of the first steps in astrophysical
                      data analysis.'"),
                    p("The whitened data is in the following plot, note that the y-axis
                      scale is now in standard deviations away from the mean."),
                    box( plotlyOutput('p_white'), width = '500' ),
                    box( dataTableOutput( 't_white' ), width = '500' )
            ),
            tabItem('final_sig',
                    h2('Final Signal: Whitened + Filtered'),
                    p("After whitening, we get rid of the high frequency noise by
                      filtering the signal. In addition to filtering, the L1 signal was
                      shifted by 7 ms for alignment 'because the source is roughly in the
                      direction of the line connecting H1 to L1, and the wave travels at
                      the speed of light, so it hits L1 7 ms earlier' [2]. We also had to
                      correct for the orientation of the sensors by flipping one of the
                      signs on the signals."),
                    p("The signal is now clear and aligns well with the theoretical
                      waveform predicted by General Relativity, 'It's exactly the kind of
                      signal we expect from the inspiral, merger and ringdown of two
                      massive black holes, as evidenced by the good match with the
                      numerical relativity (NR) waveform' [2]."),
                    box( plotlyOutput('p_final'), width = '500' ),
                    box( dataTableOutput( 't_final' ), width = '500' )
            )
        )
    )
)
