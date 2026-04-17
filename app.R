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
ui <- page_sidebar(
  theme = app_theme,
  
  # ----- Global sidebar with tabs ----- 
  sidebar = sidebar(
    width = 280,
    
    # Style for entire sidebar
    tags$style("
    .sidebar-content .nav-pills, 
    .sidebar-content .card, 
    .sidebar-content .well {
      background-color: transparent !important;
      border: none !important;
      margin-top: -20px !important;
    }

    .sidebar-content {
      display: flex !important;
      flex-direction: column !important;
      height: 100% !important;
    }
    
    #main_nav.nav-pills {
      padding-top: 0px !important;
      margin-top: 0px !important;
    }

    #main_nav .nav-link {
      color: gray !important;
      padding: 10px 15px;
    }

    #main_nav .nav-link.active {
      background-color: #2c3e50 !important;
      color: white !important;
    }
    
    #main_nav .nav-link:hover:not(.active) {
          color: black !important;     
    }
  "),
    
    title = tagList(
      tags$strong("Justice Under Pressure", style = "display: block; margin-top: -40px; font-size:1.5rem;"),
      tags$small("NSW Crime & Court Dashboard", style = "opacity:0.55; margin-top:-10px; display: block;")
    ),
    
    hr(style = 'margin-top:-5px'),
    div("ANALYSIS", style = "opacity:0.55; font-size:0.8rem;"),
    
    # Nav between tabs
    navset_pill_list(
      id = "main_nav", 
      widths = c(12, 12),
      nav_panel(title = "Crime Overview", value = "tab1", icon = icon("chart-line")),
      nav_panel(title = "Court Demand", value = "tab2", icon = icon("gavel")),
      nav_panel(title = "Regional Analysis", value = "tab3", icon = icon("map-location-dot"))
    ),
    
    
    # Footer
    div(
      class = "sidebar-footer",
      style = "margin-top: auto; padding-top: 20px;",
      hr(style = "opacity: 0.2;"),
      tags$small(
        style = "color: #6c757d; display: block; padding-bottom: 10px;",
        tags$strong("DATA5002"), tags$br(),
        "Pushkal · Varsha · Kavya"
      )
    )
  ),
  
  # Container for plots 
  navset_hidden(
    id = "content_tabs",
    selected = "tab1",
    nav_panel_hidden(value = "tab1", tab1_ui("tab1")),
    nav_panel_hidden(value = "tab2", tab2_ui("tab2")),
    nav_panel_hidden(value = "tab3", tab3_ui("tab3"))
  )
)

# ============================================================
# SERVER
# ============================================================
server <- function(input, output, session) {
  
  # Checks with tab is selected and renders accordingly
  observeEvent(input$main_nav, {
    req(input$main_nav) 
    nav_select("content_tabs", input$main_nav)
  }, ignoreInit = FALSE)
  
  tab1_server("tab1")
  tab2_server("tab2")
  tab3_server("tab3")
 
}


# ============================================================
# RUN
# ============================================================
shinyApp(ui, server)


### OLD CODE
# ui <- page_navbar(
#   title = tagList(
#     tags$strong("Justice Under Pressure"),
#     tags$small(class = "text-light ms-2 opacity-75",
#                "NSW Crime & Court Dashboard")
#   ),
#   theme = app_theme,
#   navbar_options = navbar_options(
#     bg = APP_PALETTE$primary,
#     theme = "dark"
#   ),

# ---- Shared sidebar with global filters ----
# sidebar = sidebar(
#   width = 280,
#   title = "Filters",
# 
#   selectInput(
#     "global_offence",
#     label = "Offence category",
#     choices = OFFENCE_CHOICES,
#     selected = "Assault - Domestic Violence"
#   ),
# 
#   sliderInput(
#     "global_year",
#     label = "Year",
#     min = min(YEAR_CHOICES),
#     max = max(YEAR_CHOICES),
#     value = LATEST_YEAR,
#     step = 1,
#     sep = "",
#     ticks = FALSE,
#     animate = animationOptions(interval = 1500, loop = FALSE)
#   ),
# 
#   hr(),
# 
#   tags$small(class = "text-muted",
#     "Filters apply across all tabs.",
#     tags$br(),
#     "Data: BOCSAR LGA Crime Statistics, 2016–2025."
#   ),
# 
#   tags$div(
#     class = "mt-auto pt-3",
#     tags$small(class = "text-muted",
#       tags$strong("DATA5002"), tags$br(),
#       "Pushkal · Varsha · Kavya"
#     )
#   )
# ),

# ---- Tabs ----
#   nav_panel(
#     title = "Crime Overview",
#     icon  = icon("chart-line"),
#     tab1_ui("tab1")
#   ),
# 
#   nav_panel(
#     title = "Court Demand",
#     icon  = icon("gavel"),
#     tab2_ui("tab2")
#   ),
# 
#   nav_panel(
#     title = "Regional Analysis",
#     icon  = icon("map-location-dot"),
#     tab3_ui("tab3")
#   ),
# 
#   nav_spacer(),
# 
#   nav_item(
#     tags$a(
#       href = "https://github.com/",   # TODO: replace with real repo URL
#       target = "_blank",
#       class = "nav-link",
#       icon("github"), " Source"
#     )
#   ),
# 
#   header = tags$head(
#     tags$link(rel = "stylesheet", href = "custom.css"),
#     tags$meta(name = "viewport",
#               content = "width=device-width, initial-scale=1")
#   )
# )
# 
# server <- function(input, output, session) {
#   
#   # Bundle global filters into a list of reactives that all
#   # modules can consume. This keeps the module signatures clean.
#   filters <- list(
#     offence = reactive(input$global_offence),
#     year    = reactive(input$global_year)
#   )
#   
#   
#   tab1_server("tab1", filters)
#   tab2_server("tab2", filters)
#   tab3_server("tab3", filters)
# }