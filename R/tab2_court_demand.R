# ============================================================
# R/tab2_court_demand.R
# ------------------------------------------------------------
# Owner: Kavya
# Charts planned (from MS Lists):
#   - Processing time distribution
#   - Court finalizations
#   - Court cases filed in different courts
# ============================================================

tab2_ui <- function(id = "tab2") {
  ns <- NS(id)

  tagList(
    h3("Court Demand & Backlogs", class = "tab-heading"),
    p(class = "tab-desc",
      "How crime volume translates into caseload for the courts — ",
      "lodgements, finalisations, and processing times."),
    div(
      class = "row w-100 g-3", 
      column(3, card(
        card_header("CASES LODGED", style = 'opacity:0.55; font-size:0.8rem;'),
        uiOutput(ns("metric_lodged"))
      )),
      column(3, card(
        card_header("MEDIAN TIME TO COMMIT", style = 'opacity:0.55; font-size:0.8rem;'),
        uiOutput(ns("metric_commit"))
      )),
      column(3, card(
        card_header("MEDIAN TIME TO SENTENCE", style = 'opacity:0.55; font-size:0.8rem;'),
        uiOutput(ns("metric_sentence"))
      )),
      column(3, card(
        card_header("MEDIAN TIME TO FINALISE", style = 'opacity:0.55; font-size:0.8rem;'),
        uiOutput(ns("metric_finalise"))
      )),
      p('All values shown for the court type selected below', style = 'margin-top:-10px; font-size:0.8rem; opacity:0.55; font-style:italic')
    ),

    fluidRow(
      column(12,
        card(
          card_header(
            div(class = "d-flex justify-content-between align-items-center w-100",
                uiOutput(ns("dynamic_plot_title")),
                div(style = "width: 250px;", 
                    selectInput(ns("court_select"), NULL, 
                                choices = c("Supreme Court", "District Court", "Local Court", "Children's Court"),
                                selected = "Supreme Court",
                                width = "100%")
                )
            )
          ),
          plotlyOutput(ns("processing_plot"), height = "350px"),
          tags$small(class = "text-muted ps-3 pb-2",
            "Segments are proportional to the finalisation median, ",
            "not true decompositions — based on median values.")
        )
      )
    ),

    br(),

    fluidRow(
      column(6,
        card(
          card_header("Median days from arrest to finalisation by court type"),
          plotlyOutput(ns("finalisations_plot"), height = "320px")
        )
      ),
      column(6,
        card(
          card_header("Year-on-year % change in median days from arrest to finalisation"),
          plotlyOutput(ns("cases_by_court_plot"), height = "320px")
        )
      )
    )
  )
}

tab2_server <- function(id = "tab2", filters) {
  moduleServer(id, function(input, output, session) {

    # TODO (Kavya): implement the three plots.
    # Note: the crime xlsx does not contain court data — you'll need
    # the BOCSAR court processing dataset you've been working with.
    # Place it in data-raw/ and add a prep script similar to
    # data-raw/01_prepare_lga_crime.R.
    
    current_metrics <- reactive({
      req(input$court_select)
      court_bundle$main %>%
        filter(
          grepl(input$court_select, Court.Type, ignore.case = TRUE),
          grepl("2024.25", Timeframe)
        )
    })
    
    prev_year_metrics <- reactive({
      req(input$court_select)
      court_bundle$main %>%
        filter(
          grepl(input$court_select, Court.Type, ignore.case = TRUE),
          grepl("2023", Timeframe) & grepl("24", Timeframe)
        )
    })
    
    show_perc_change <- function(current, previous) {
      if (length(current) == 0 || length(previous) == 0 || previous == 0) return(tags$span(
        style = "font-size: 0.9rem; font-weight: 600; opacity: 0.6",
        "N/A"
      ))
      
      perc_change <- ((current - previous) / previous) * 100
      color <- if (perc_change >= 0) "green" else "red"
      icon  <- if (perc_change >= 0) "↑" else "↓"
      tagList(
        tags$span(
          style = paste0("color:", color, "; font-size: 0.9rem; font-weight: 600;"),
          sprintf("%s %.1f%%", icon, abs(perc_change))
        ),
        tags$span(
          style = "font-size: 0.8rem; opacity: 0.6;",
          " (compared to 2023–24)"
        )
      )
    }
    
    output$metric_lodged <- renderUI({
      curr <- current_metrics()$Count
      prev <- prev_year_metrics()$Count
      div(
        div(style = "font-size: 1.8rem; font-weight: 700; display: flex;", 
            if(length(curr) > 0) format(curr, big.mark = ",") else "N/A"),
        show_perc_change(curr, prev)
      )
    })
    
    output$metric_commit <- renderUI({
      curr <- current_metrics()$Arrest.to.committal..c.
      prev <- prev_year_metrics()$Arrest.to.committal..c.
      div(
        div(style = "font-size: 1.8rem; font-weight: 700; display: flex;", 
            if(length(curr) > 0) paste(curr, 'days') else "N/A"),
        show_perc_change(curr, prev)
      )
    })
    
    # Render Backlog
    output$metric_sentence <- renderUI({
      curr <- current_metrics()$Outcome.to.sentence
      prev <- prev_year_metrics()$Outcome.to.sentence
      div(
        div(style = "font-size: 1.8rem; font-weight: 700; display: flex;", 
            if(length(curr) > 0) paste(curr, 'days') else "N/A"),
        show_perc_change(curr, prev)
      )
    })
    
    # Render Median Time
    output$metric_finalise <- renderUI({
      curr <- current_metrics()$Arrest.to.finalisation..c.
      prev <- prev_year_metrics()$Arrest.to.finalisation..c.
      div(
        div(style = "font-size: 1.8rem; font-weight: 700; display: flex;", 
            if(length(curr) > 0) paste(curr, 'days') else "N/A"),
        show_perc_change(curr, prev)
      )
    })
    
   
    # Graph 1 : Processing time distribution
    ## change name of title based on the court type selected
    output$dynamic_plot_title <- renderUI({
      req(input$court_select)
      span(paste(input$court_select, "Processing Time Distribution"), 
           style = "font-weight: 600;")
    })
    
    output$processing_plot <- renderPlotly({
      req(input$court_select)
      plot_df <- court_bundle$percent_long %>% 
        filter(Court.Type == input$court_select) %>%
        mutate(stage = factor(stage, 
                              levels = c("arrest_to_comm_perc", "comm_to_outcome_perc", "outcome_to_sent_perc"),
                              labels = c("Arrest to committal", "Committal to outcome", "Outcome to sentence")))
      p <- ggplot(plot_df, aes(x=Timeframe, y=percentage, fill=stage, 
                               text=paste0(
                                 "Year: ", Timeframe,
                                 "<br>Stage: ", stage,
                                 "<br>Percentage (of time): ", round(percentage, 2), '%'
                               )
                               )) + 
        geom_col() +  
        labs(
          # title = paste("Breakdown of", input$court_select, "case processing time"),
          # subtitle = "Each stage shown as a proportion of median arrest-to-finalisation time",
          x = "Financial year",
          y = "% of arrest-to-finalisation time",
          fill = "Stage"
        ) +
        scale_fill_manual(
          values = c(
            "Arrest to committal"   = APP_PALETTE$primary,
            "Committal to outcome"  = APP_PALETTE$secondary,
            "Outcome to sentence"  = APP_PALETTE$accent
          )
        ) + 
        theme(
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          panel.background = element_blank(),
          axis.line.x = element_line(colour = "black"),
          axis.line.y = element_line(colour = "black")
        ) +
        scale_y_continuous(
          expand = c(0, 0)
        )
      
      ggplotly(p, tooltip = 'text')
    })

    # Graph 2 : Arrest to finalisation time for courts
    output$finalisations_plot <- renderPlotly({
      plot_df_2 <- court_bundle$main 
      p2 <- ggplot(plot_df_2, aes(x = Timeframe, y = Arrest.to.finalisation..c., color = Court.Type, group = Court.Type, 
                                  text=paste0(
                                    "Year: ", Timeframe,
                                    "<br>Median Days: ", Arrest.to.finalisation..c.
                                  ))) + 
        geom_line(size=0.4) + 
        geom_point(size=0.8) + 
        labs(
          # title = "Median days from arrest to finalisation by court type",
          x = "Financial year",
          y = "Median days",
          colour = "Court type",
        ) +
        scale_colour_manual(values = c(
          "Supreme Court"    = COLOR_BLIND_PALETTE$primary,
          "District Court"   = COLOR_BLIND_PALETTE$secondary,
          "Local Court"      = COLOR_BLIND_PALETTE$support1,
          "Children's Court" = COLOR_BLIND_PALETTE$support4
        )) + 
        theme(
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          panel.background = element_blank(),
          axis.line.x = element_line(colour = "black"),
          axis.line.y = element_line(colour = "black")
        ) +
        scale_y_continuous(
          expand = c(0, 0),
          limits = c(0, 1200)
        )
      
      
      ggplotly(p2, tooltip = 'text') %>%
        onRender("
          function(el) {
          el.on('plotly_hover', function(d) {
            var pn = d.points[0].curveNumber;
            // 1. Dim all lines first
            var dim = { 'line.width': 1.2, 'opacity': 0.2 };
            Plotly.restyle(el, dim);

            // 2. Highlight the specific hovered line
            var highlight = { 'line.width': 1.2, 'opacity': 1 };
            Plotly.restyle(el, highlight, [pn]);
          });
          el.on('plotly_unhover', function(d) {
            // Reset everything to normal when leaving
            var reset = { 'line.width': 1.2, 'opacity': 1 };
            Plotly.restyle(el, reset);
          });
        }
      ")
    })

    # Graph 3 : Cases filed by court
    output$cases_by_court_plot <- renderPlotly({
      plot_df_3 <- court_bundle$percent_change
      p3 <- ggplot(plot_df_3, aes(x = Timeframe, y = perc_change, color = Court.Type, group = Court.Type, 
                                  text=paste0(
                                    "Year: ", Timeframe,
                                    "<br>Change: ", round(perc_change, 2), "%"
                                  )
                                  )) + 
        geom_line(size=0.4) + 
        geom_point(size=0.8) + 
        labs(
          # title = "Year-on-year % change in median days from arrest to finalisation",
          x = "Financial year",
          y = "% Change",
          colour = "Court type",
        ) +
        scale_colour_manual(values = c(
          "Supreme Court"    = COLOR_BLIND_PALETTE$primary,
          "District Court"   = COLOR_BLIND_PALETTE$secondary,
          "Local Court"      = COLOR_BLIND_PALETTE$support1,
          "Children's Court" = COLOR_BLIND_PALETTE$support4
        )) + 
        geom_hline(aes(yintercept = 0), color='gray', alpha = 0.4, linewidth=0.3) +
        theme(
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          panel.background = element_blank(),
          axis.line.x = element_line(colour = "black"),
          axis.line.y = element_line(colour = "black")
        ) +
        scale_y_continuous(labels = function(x) paste0(x, "%"))
      
      ggplotly(p3, tooltip = "text") %>%
        
        onRender("
          function(el) {
          el.on('plotly_hover', function(d) {
            var pn = d.points[0].curveNumber;
            // 1. Dim all lines first
            var dim = { 'line.width': 1.2, 'opacity': 0.2 };
            Plotly.restyle(el, dim);
      
            // 2. Highlight the specific hovered line
            var highlight = { 'line.width': 1.2, 'opacity': 1 };
            Plotly.restyle(el, highlight, [pn]);
          });
          el.on('plotly_unhover', function(d) {
            // Reset everything to normal when leaving
            var reset = { 'line.width': 1.2, 'opacity': 1 };
            Plotly.restyle(el, reset);
          });
        }
      ")
    })
    
    
  })
}
