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

    fluidRow(
      column(12,
        card(
          card_header("Processing Time Distribution"),
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
          card_header("Court Finalizations"),
          plotlyOutput(ns("finalisations_plot"), height = "320px")
        )
      ),
      column(6,
        card(
          card_header("Cases Filed by Court"),
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

    output$processing_plot <- renderPlotly({
      plotly_empty(type = "bar") |>
        layout(title = "Processing time — TODO")
    })

    output$finalisations_plot <- renderPlotly({
      plotly_empty(type = "scatter", mode = "lines") |>
        layout(title = "Finalisations — TODO")
    })

    output$cases_by_court_plot <- renderPlotly({
      plotly_empty(type = "bar") |>
        layout(title = "Cases by court — TODO")
    })
  })
}
