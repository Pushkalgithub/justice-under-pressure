# ============================================================
# R/tab3_regional.R
# ------------------------------------------------------------
# Owner: Pushkal
# Charts planned (from MS Lists):
#   - NSW crime heatmap (choropleth)
#   - Crime rate by region graph
#   - Crime rates in and around Sydney
# ============================================================

tab3_ui <- function(id = "tab3") {
  ns <- NS(id)

  tagList(
    h3("Regional Analysis", class = "tab-heading"),
    p(class = "tab-desc",
      "Geographic lens on crime across NSW — where are the hotspots?"),

    fluidRow(
      column(12,
        card(
          card_header("NSW Crime Heatmap"),
          div(class = "text-muted text-center py-5",
              tags$em("TODO — choropleth map"))
        )
      )
    ),

    br(),

    fluidRow(
      column(12,
        card(
          card_header("Crime Rate by Region"),
          div(class = "text-muted text-center py-5",
              tags$em("TODO — ranked bar chart"))
        )
      )
    ),

    br(),

    fluidRow(
      column(12,
        card(
          card_header("Crime Rates In and Around Sydney"),
          div(class = "text-muted text-center py-5",
              tags$em("TODO — Sydney zoom map"))
        )
      )
    )
  )
}

tab3_server <- function(id = "tab3", filters) {
  moduleServer(id, function(input, output, session) {
    # TODO: implement in next commit
  })
}
