function( input, output )
{
    output$p_raw <- renderPlotly( h.raw     )
    output$t_raw <- renderDataTable( pd.raw )

    output$p_white <- renderPlotly( h.white   )
    output$t_white <- renderDataTable( pd.white )

    output$p_final <- renderPlotly( h.whitebp )
    output$t_final <- renderDataTable( pd.whitebp )
}
