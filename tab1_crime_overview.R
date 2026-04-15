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
          plotlyOutput(ns("trend_plot"), height = "350px")
        )
      )
    ),

    br(),

    fluidRow(
      column(6,
        card(
          card_header("Offence Category Breakdown"),
          plotlyOutput(ns("breakdown_plot"), height = "320px")
        )
      ),
      column(6,
        card(
          card_header("Top Offences by Volume"),
          plotlyOutput(ns("top_offences_plot"), height = "320px")
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

    output$trend_plot <- renderPlotly({
      plotly_empty(type = "scatter", mode = "lines") |>
        layout(title = "Trend plot — TODO")
    })

    output$breakdown_plot <- renderPlotly({
      plotly_empty(type = "scatter", mode = "markers") |>
        layout(title = "Breakdown — TODO")
    })

    output$top_offences_plot <- renderPlotly({
      plotly_empty(type = "bar") |>
        layout(title = "Top offences — TODO")
    })
  })
}
