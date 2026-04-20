# ============================================================
# R/tab1_crime_overview.R
# ------------------------------------------------------------
# Owner: Varsha
# Charts planned (from MS Lists):
#   - Crime trend over time
#   - Offence category breakdown
#   - Top offences by volume
# ============================================================

tab1_ui <- function(id = "tab1") {
  ns <- NS(id)

  tagList(
    h3("Crime Overview", class = "tab-heading"),
    p(class = "tab-desc",
      "High-level snapshot of crime trends across NSW — incidents, ",
      "offence breakdowns, and year-over-year shifts."),

    fluidRow(
      column(12,
        card(
          card_header("Crime Trend Over Time"),
          fluidRow(
            column(5, 
                   div(
                     tags$label("Offence Category", `for` = ns("offence_category"), class = "control-label"),
                     
                     # warning for categories selected
                     uiOutput(ns("picker_warning")),
                     
                     pickerInput(
                       inputId = ns("offence_category"), 
                       label = NULL, 
                       choices = unique(crime_bundle$main$offence_category), 
                       selected = c("Theft", "Malicious Damage to Property", "Assault", 
                                    "Transport Regulatory Offence", "Justice Violation"),
                       multiple = TRUE,
                       options = list(
                         `live-search` = TRUE,
                         `max-options` = 7,
                         `max-options-text` = list("Limit reached", "Maximum 7 categories allowed")
                       )
                     )
                   )
            ),
            column(5, 
              sliderInput(inputId = ns("year_line"),
                          label = "Year",
                          min = 1995,
                          max = 2025,
                          value = c(2020, 2025),
                          step = 1,
                          sep = ""
              )
            ),
            column(2,
               tags$div(
                 style = "margin-top: 20px;", 
                 actionButton(inputId = ns("apply_line"), label = "Apply")
               )
            )
          ),
          plotlyOutput(ns("trend_plot"), height = "400px")
        )
      )
    ),

    br(),

    fluidRow(
      column(6,
        card(
          card_header("Offence Category Breakdown"),
          tags$div(
            sliderInput(inputId = ns("year_bar"),
                        label = "Year",
                        min = 1995,
                        max = 2025,
                        value = c(2020, 2025),
                        step = 1,
                        sep = ""
            ),
            actionButton(inputId = ns("apply_bar"), label = "Apply")
          ),
          plotlyOutput(ns("breakdown_plot"), height = "320px")
        )
      ),
      column(6,
        card(
          card_header("Top Offences by Volume"),
          tags$div(
            numericInput(inputId = ns("year_table"),
                         label = "Year",
                         min = 1995,
                         max = 2025,
                         value = 2025,
                         step = 1,
            ),
            actionButton(inputId = ns("apply_table"), label = "Apply")
          ),
          dataTableOutput(ns("top_offences_table"), height = "320px")
        )
      )
    )
  )
}

tab1_server <- function(id = "tab1", filters) {
  moduleServer(id, function(input, output, session) {

    # TODO (Varsha): implement the three plots.
    # Use filter_crime() from global.R to get filtered data.
    # Colour palette: APP_PALETTE in global.R.
    
    
    # Crime Trend Over Time
    
    prev_selection <- reactiveVal(NULL)
    
    observeEvent(input$offence_category, {
      
      #  No categories selected
      
      current <- input$offence_category
      previous <- prev_selection()
      
      # Initialize first time
      if (is.null(previous)) {
        prev_selection(current)
        return()
      }
      
      # Detect what was unchecked
      removed <- setdiff(previous, current)
      
      if (length(input$offence_category) == 0) {
        last_removed <- tail(removed, 1)
        showNotification("Select at least one offence category", type = "error")
        updatePickerInput(
          session,
          inputId = "offence_category",
          selected = last_removed
        )
        return()
      }
      prev_selection(current)
      
      
    }, ignoreNULL = FALSE)
    
    # warning for categories selected
    output$picker_warning <- renderUI({
      if(length(input$offence_category) >= 7) {
        tags$div(
          style = "color: #d9534f; font-size: 0.85rem; font-weight: bold; margin-top: 5px; margin-bottom: 5px",
          "Maximum 7 categories reached."
        )
      } else {
        tags$div(
          style = "color: #666; font-size: 0.8rem; margin-top: 5px; margin-bottom:5px",
          paste0(length(input$offence_category), " of 7 categories selected")
        )
      }
    })
    
    
    observeEvent(input$year_line, {
      
      req(input$year_line)
      
      if ((input$year_line[2] - input$year_line[1]) > 10) {
        showNotification("Maximum 10-year range allowed", type = "error")
        updateSliderInput(
          session,
          inputId = "year_line",
          value = c(input$year_line[2]-10, input$year_line[2])
        )
      }
      
    }, ignoreNULL = FALSE)
    
    filtered_data_line <- eventReactive(input$apply_line, {
      req(input$offence_category)
      req(input$year_line)
      crime_bundle$main %>%
        filter(
          offence_category %in% input$offence_category,
          year %in% seq(input$year_line[1], input$year_line[2])
        )
    }, ignoreNULL = FALSE)
    
    output$trend_plot <- renderPlotly({
      
      dt <- filtered_data_line()
      req(dt)
      dt$offence_category <- str_wrap(dt$offence_category, width=20)
      df <- highlight_key(dt, ~offence_category)
      p <- ggplot(df,
                  aes(x=quarter_date, y=crime_count, colour=offence_category, group=offence_category,
                      text=paste0(
                        "Quarter: ", format(quarter_date, "Q%q %Y"),
                        "<br>Count: ", crime_count
                      ))) +
        geom_line(size=0.4) +
        geom_point(size=0.8) +
        scale_x_yearqtr(format="Q%q %Y",
                        breaks=seq(
                          min(dt$quarter_date),
                          max(dt$quarter_date),
                          by=0.25
                        ),
                        expand=c(0,0)
        ) +
        scale_y_continuous(
          limits = c(0, NA),
          labels = scales::label_number(scale = 1e-3, suffix = "K"),
          breaks = scales::pretty_breaks(n = 10)
        ) +
        scale_color_manual(values=c(
          COLOR_BLIND_PALETTE$primary,
          COLOR_BLIND_PALETTE$secondary,
          COLOR_BLIND_PALETTE$support1,
          COLOR_BLIND_PALETTE$support5,
          COLOR_BLIND_PALETTE$support2,
          COLOR_BLIND_PALETTE$support4,
          COLOR_BLIND_PALETTE$support6          
          )
        ) +
        labs(
          x="Quarter",
          y="Crime Count",
          colour="Offence Category"
        ) +
        theme(
          plot.title=element_text(hjust=0.5, size=13, face="bold"), # Center title
          axis.text.x=element_text(angle=90, hjust=1), # Rotate x labels
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          panel.background = element_blank(),
          plot.background = element_blank()
        )
      
      # ggplotly(p, tooltip="text") %>%
      #   highlight(
      #     on = "plotly_hover",
      #     off = "plotly_doubleclick",
      #     opacityDim = 0.4,   # fade others
      #     selected = attrs_selected(
      #       line = list(width = 2),   # bold selected
      #       showlegend = FALSE
      #     )
      #   )
      
      ggplotly(p, tooltip = 'text') %>%
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
    
    
    # Offence Category Breakdown
    
    observeEvent(input$year_bar, {
      
      req(input$year_bar)
      
      if ((input$year_bar[2] - input$year_bar[1]) > 10) {
        showNotification("Maximum 10-year range allowed", type = "error")
        updateSliderInput(
          session,
          inputId = "year_bar",
          value = c(input$year_bar[2]-10, input$year_bar[2])
        )
      }
      
    }, ignoreNULL = FALSE)
    
    filtered_data_bar <- eventReactive(input$apply_bar, {
      
      req(input$year_bar)
      
      req_data <- crime_bundle$main %>%
        filter(
          year %in% seq(input$year_bar[1], input$year_bar[2])
        )
      
      top_offences <- req_data %>%
        group_by(offence_category) %>%
        summarise(total=sum(crime_count, na.rm=TRUE), .groups="drop") %>%
        arrange(desc(total)) %>%
        slice_head(n=5) %>%
        pull(offence_category)
      
      req_data %>%
        filter(offence_category %in% top_offences) %>%
        group_by(year, offence_category) %>%
        summarise(crime_count=sum(crime_count, na.rm=TRUE), .groups="drop") %>%
        arrange(year)
      
    }, ignoreNULL = FALSE)
    
    output$breakdown_plot <- renderPlotly({
      
      dt <- filtered_data_bar()
      req(dt)
      dt$offence_category <- str_wrap(dt$offence_category, width=20)
      p <- ggplot(dt,
                  aes(x=factor(year), y=crime_count, fill=offence_category,
                      text=paste0(
                        "Year: ", year,
                        "<br>Offence: ", offence_category,
                        "<br>Total: ", crime_count
                      ))) +
        geom_bar(stat="identity") +
        scale_y_continuous(
          limits = c(0, NA),
          labels = scales::label_number(scale = 1e-3, suffix = "K"),
          breaks = scales::pretty_breaks(n = 5)
        ) +
        scale_fill_manual(values=c(
          APP_PALETTE$primary,
          APP_PALETTE$secondary,
          APP_PALETTE$accent,
          APP_PALETTE$neutral,
          APP_PALETTE$text
        )) +
        labs(
          x="Year",
          y="Crime Count",
          fill="Offence Category"
        ) +
        theme(
          plot.title=element_text(hjust=0.5, size=13, face="bold"), # Center title
          axis.text.x=element_text(angle=90, hjust=1), # Rotate x labels
          panel.grid.major = element_blank(),
          panel.grid.minor = element_blank(),
          panel.background = element_blank(),
          plot.background = element_blank()
        )
      
      ggplotly(p, tooltip="text")
    })
    
    
    # Top Offences by Volume
    
    filtered_data_table <- eventReactive(input$apply_table, {
      
      req(input$year_table)
      
      req_data <- crime_bundle$main %>%
        filter(year==input$year_table)
      
      req_data %>%
        group_by(offence_category) %>%
        summarise(crime_count=sum(crime_count, na.rm=TRUE), .groups="drop") %>%
        arrange(desc(crime_count)) %>%
        slice_head(n=5) %>%
        rename("Offence Category"=offence_category, "Crime Count"=crime_count)
      
    }, ignoreNULL = FALSE)
    
    output$top_offences_table <- renderDataTable({
      req(filtered_data_table())
      
      datatable(
        filtered_data_table(),
        rownames = FALSE,
        class = "cell-border stripe",   # adds borders + stripes
        options = list(
          dom = 't',        # removes search/pagination
          pageLength = 5,
          autoWidth = TRUE,
          scrollX = FALSE,
          scrollY = FALSE
        ),
        fillContainer = TRUE
      )
    })
  })
}
