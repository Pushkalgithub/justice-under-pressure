# ============================================================
# app.R
# ------------------------------------------------------------
# Main entry point. Shiny looks for app.R by default.
# Run with: shiny::runApp() from the project root.
# ============================================================

# Load shared state (packages, data, constants, helpers)
source("global.R")

# Load tab modules
source("R/tab1_crime_overview.R")
source("R/tab2_court_demand.R")
source("R/tab3_regional.R")


# ============================================================
# UI
# ============================================================
ui <- page_navbar(
  title = tagList(
    tags$strong("Justice Under Pressure"),
    tags$small(class = "text-light ms-2 opacity-75",
               "NSW Crime & Court Dashboard")
  ),
  theme = app_theme,
  bg    = APP_PALETTE$primary,
  inverse = TRUE,

  # ---- Shared sidebar with global filters ----
  sidebar = sidebar(
    width = 280,
    title = "Filters",

    selectInput(
      "global_offence",
      label = "Offence category",
      choices = OFFENCE_CHOICES,
      selected = "Assault - Domestic Violence"
    ),

    sliderInput(
      "global_year",
      label = "Year",
      min = min(YEAR_CHOICES),
      max = max(YEAR_CHOICES),
      value = LATEST_YEAR,
      step = 1,
      sep = "",
      ticks = FALSE,
      animate = animationOptions(interval = 1500, loop = FALSE)
    ),

    hr(),

    tags$small(class = "text-muted",
      "Filters apply across all tabs.",
      tags$br(),
      "Data: BOCSAR LGA Crime Statistics, 2016–2025."
    ),

    tags$div(
      class = "mt-auto pt-3",
      tags$small(class = "text-muted",
        tags$strong("DATA5002"), tags$br(),
        "Pushkal · Varsha · Kavya"
      )
    )
  ),

  # ---- Tabs ----
  nav_panel(
    title = "Crime Overview",
    icon  = icon("chart-line"),
    tab1_ui("tab1")
  ),

  nav_panel(
    title = "Court Demand",
    icon  = icon("gavel"),
    tab2_ui("tab2")
  ),

  nav_panel(
    title = "Regional Analysis",
    icon  = icon("map-location-dot"),
    tab3_ui("tab3")
  ),

  nav_spacer(),

  nav_item(
    tags$a(
      href = "https://github.com/",   # TODO: replace with real repo URL
      target = "_blank",
      class = "nav-link",
      icon("github"), " Source"
    )
  ),

  header = tags$head(
    tags$link(rel = "stylesheet", href = "custom.css"),
    tags$meta(name = "viewport",
              content = "width=device-width, initial-scale=1")
  )
)


# ============================================================
# SERVER
# ============================================================
server <- function(input, output, session) {

  # Bundle global filters into a list of reactives that all
  # modules can consume. This keeps the module signatures clean.
  filters <- list(
    offence = reactive(input$global_offence),
    year    = reactive(input$global_year)
  )

  tab1_server("tab1", filters)
  tab2_server("tab2", filters)
  tab3_server("tab3", filters)
}


# ============================================================
# RUN
# ============================================================
shinyApp(ui, server)
