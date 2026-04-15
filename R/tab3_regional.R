# ============================================================
# R/tab3_regional.R
# ------------------------------------------------------------
# Owner: Pushkal
# Charts (from MS Lists):
#   - NSW crime heatmap (choropleth, Leaflet)
#   - Crime rate by region graph (ranked bar)
#   - Crime rates in and around Sydney (zoomed choropleth)
#
# Note: BOCSAR ranks LGAs in decreasing order of rate per 100k
# (rank 1 = highest rate). Since rank is a monotonic function
# of rate, we colour-grade by rank only — it encodes the same
# ordering and is cleaner to read.
# ============================================================

tab3_ui <- function(id = "tab3") {
  ns <- NS(id)

  tagList(
    h3("Regional Analysis", class = "tab-heading"),
    p(class = "tab-desc",
      "Geographic lens on crime across NSW — where are the hotspots, ",
      "and how do LGAs stack up against each other? Click a region on the ",
      "map or a bar in the ranking to drill down. Regions are coloured by ",
      "their rank (1 = highest rate per 100,000 population)."),

    fluidRow(
      column(8,
        card(
          card_header("NSW Crime Heatmap"),
          leafletOutput(ns("nsw_map"), height = "520px")
        )
      ),
      column(4,
        card(
          card_header("Selected Region"),
          uiOutput(ns("region_summary"))
        ),
        br(),
        card(
          card_header("Top 10 LGAs by Rate"),
          plotlyOutput(ns("top10_plot"), height = "340px")
        )
      )
    ),

    br(),

    # ---- Full ranked bar chart ----
    fluidRow(
      column(12,
        card(
          card_header(
            class = "d-flex justify-content-between align-items-center",
            span("Crime Rate by Region — Ranked"),
            div(
              class = "d-flex align-items-center gap-2",
              tags$small("Show:", class = "text-muted"),
              selectInput(
                ns("rank_scope"),
                label = NULL,
                choices = c("Top 20" = "top20",
                            "Bottom 20" = "bot20",
                            "All LGAs" = "all"),
                selected = "top20",
                width = "140px"
              )
            )
          ),
          plotlyOutput(ns("ranked_bar"), height = "500px")
        )
      )
    ),

    br(),

    # ---- Sydney zoom view ----
    fluidRow(
      column(12,
        card(
          card_header("Crime Rates In and Around Sydney"),
          p(class = "text-muted small px-3 pt-2",
            "Zoomed view of Greater Sydney LGAs only. ",
            "Uses the same rank-based colour scale as the statewide map."),
          leafletOutput(ns("sydney_map"), height = "480px")
        )
      )
    )
  )
}

tab3_server <- function(id = "tab3", filters) {
  moduleServer(id, function(input, output, session) {

    # ---- Reactive: filtered crime data for the selected offence & year ----
    tab_data <- reactive({
      req(filters$offence(), filters$year())
      filter_crime(
        offence = filters$offence(),
        year    = filters$year()
      )
    })

    # ---- Reactive: join crime data with LGA geometry ----
    map_data <- reactive({
      req(tab_data())
      if (is.null(nsw_lga_sf)) return(NULL)

      nsw_lga_sf |>
        left_join(tab_data(), by = "lga")
    })

    # ---- Colour palette: rank-based ----
    # Rank 1 = highest rate → darkest red.
    # colorNumeric with reversed ramp so low ranks map to the "hot" end.
    pal_fn <- reactive({
      req(map_data())
      colorNumeric(
        palette  = rev(CHOROPLETH_RAMP),
        domain   = map_data()$rank,
        na.color = "#e8e8e8"
      )
    })

    # ---- Tracks the clicked LGA ----
    selected_lga <- reactiveVal(NULL)

    # ============================================================
    # MAP 1 — NSW statewide choropleth
    # ============================================================
    output$nsw_map <- renderLeaflet({
      leaflet(options = leafletOptions(zoomControl = TRUE,
                                       minZoom = 5, maxZoom = 11)) |>
        addProviderTiles(providers$CartoDB.Positron) |>
        setView(lng = 146.5, lat = -32.5, zoom = 6)
    })

    observe({
      md <- map_data()
      req(md)
      pal <- pal_fn()

      labels <- sprintf(
        "<strong>%s</strong><br/>Rate: %s per 100k<br/>Rank: %s",
        md$lga,
        fmt_rate(md$rate_per_100k),
        fmt_rank(md$rank)
      ) |> lapply(htmltools::HTML)

      leafletProxy("nsw_map", data = md) |>
        clearShapes() |>
        clearControls() |>
        addPolygons(
          fillColor   = pal(md$rank),
          weight      = 0.6,
          opacity     = 1,
          color       = "white",
          fillOpacity = 0.85,
          highlightOptions = highlightOptions(
            weight = 2,
            color  = APP_PALETTE$primary,
            fillOpacity = 0.95,
            bringToFront = TRUE
          ),
          label = labels,
          labelOptions = labelOptions(
            style = list("font-weight" = "500", padding = "6px 10px"),
            textsize = "12px",
            direction = "auto"
          ),
          layerId = ~lga
        ) |>
        addLegend(
          position = "bottomright",
          pal      = pal,
          values   = md$rank,
          title    = "Rank (1 = worst)",
          opacity  = 0.9
        )
    })

    # ---- Click handler ----
    observeEvent(input$nsw_map_shape_click, {
      selected_lga(input$nsw_map_shape_click$id)
    })

    # ============================================================
    # Region summary panel
    # ============================================================
    output$region_summary <- renderUI({
      lga <- selected_lga()

      if (is.null(lga)) {
        return(div(class = "text-muted text-center py-4",
                   tags$em("Click a region on the map to see details")))
      }

      row <- tab_data() |> filter(lga == !!lga)
      if (nrow(row) == 0) {
        return(div(class = "text-muted", "No data for this region."))
      }

      div(
        h4(lga, style = paste0("color:", APP_PALETTE$primary, ";",
                               "font-weight:600;")),
        tags$hr(),
        div(class = "row g-2",
          div(class = "col-6",
            tags$small(class = "text-muted", "Rate per 100k"),
            div(style = "font-size: 1.4rem; font-weight: 600;",
                fmt_rate(row$rate_per_100k))
          ),
          div(class = "col-6",
            tags$small(class = "text-muted", "Rank"),
            div(style = "font-size: 1.4rem; font-weight: 600;",
                fmt_rank(row$rank))
          )
        ),
        tags$hr(),
        tags$small(class = "text-muted", "10-year trend"),
        plotlyOutput(session$ns("sparkline"), height = "80px")
      )
    })

    output$sparkline <- renderPlotly({
      lga <- selected_lga(); req(lga)
      trend <- filter_crime(offence = filters$offence(), lgas = lga) |>
        arrange(year)

      plot_ly(trend, x = ~year, y = ~rate_per_100k,
              type = "scatter", mode = "lines+markers",
              line = list(color = APP_PALETTE$primary, width = 2),
              marker = list(color = APP_PALETTE$primary, size = 5),
              hovertemplate = "%{x}: %{y:.0f}<extra></extra>") |>
        layout(
          margin = list(l = 0, r = 0, t = 0, b = 20),
          xaxis = list(title = "", showgrid = FALSE, fixedrange = TRUE),
          yaxis = list(title = "", showgrid = FALSE, fixedrange = TRUE),
          showlegend = FALSE,
          plot_bgcolor = "rgba(0,0,0,0)",
          paper_bgcolor = "rgba(0,0,0,0)"
        ) |>
        config(displayModeBar = FALSE)
    })

    # ============================================================
    # Top 10 mini bar chart
    # ============================================================
    output$top10_plot <- renderPlotly({
      df <- tab_data() |>
        filter(!is.na(rate_per_100k)) |>
        arrange(desc(rate_per_100k)) |>
        head(10)

      plot_ly(
        df,
        x = ~rate_per_100k,
        y = ~reorder(lga, rate_per_100k),
        type = "bar",
        orientation = "h",
        marker = list(
          color = ~rate_per_100k,
          colorscale = list(
            c(0, APP_PALETTE$secondary),
            c(1, APP_PALETTE$danger)
          ),
          line = list(width = 0)
        ),
        hovertemplate = "<b>%{y}</b><br>Rate: %{x:.0f}<extra></extra>"
      ) |>
        layout(
          margin = list(l = 10, r = 10, t = 10, b = 30),
          xaxis = list(title = "Rate per 100k"),
          yaxis = list(title = ""),
          plot_bgcolor = "rgba(0,0,0,0)",
          paper_bgcolor = "rgba(0,0,0,0)"
        ) |>
        config(displayModeBar = FALSE)
    })

    # ============================================================
    # Full ranked bar chart
    # ============================================================
    output$ranked_bar <- renderPlotly({
      df <- tab_data() |> filter(!is.na(rate_per_100k))

      df <- switch(input$rank_scope,
        top20 = df |> arrange(desc(rate_per_100k)) |> head(20),
        bot20 = df |> arrange(rate_per_100k) |> head(20),
        all   = df |> arrange(desc(rate_per_100k))
      )

      # Highlight selected LGA if any
      sel <- selected_lga()
      df <- df |>
        mutate(is_selected = !is.null(sel) & lga == sel)

      bar_colours <- ifelse(
        df$is_selected,
        APP_PALETTE$accent,
        APP_PALETTE$primary
      )

      plot_ly(
        df,
        x = ~reorder(lga, -rate_per_100k),
        y = ~rate_per_100k,
        type = "bar",
        marker = list(color = bar_colours),
        text = ~paste0("Rank #", rank),
        textposition = "none",
        hovertemplate = paste0(
          "<b>%{x}</b><br>",
          "Rate: %{y:.0f} per 100k<br>",
          "%{text}<extra></extra>"
        ),
        source = "ranked_bar",
        key = ~lga
      ) |>
        layout(
          margin = list(l = 50, r = 20, t = 20, b = 120),
          xaxis = list(title = "",
                       tickangle = -45,
                       automargin = TRUE),
          yaxis = list(title = "Rate per 100,000 population"),
          plot_bgcolor = "rgba(0,0,0,0)",
          paper_bgcolor = "rgba(0,0,0,0)"
        ) |>
        config(displayModeBar = FALSE)
    })

    # Click a bar to update selected LGA
    observeEvent(event_data("plotly_click", source = "ranked_bar"), {
      d <- event_data("plotly_click", source = "ranked_bar")
      if (!is.null(d$key)) selected_lga(d$key)
    })

    # ============================================================
    # MAP 2 — Greater Sydney zoom
    # ============================================================
    output$sydney_map <- renderLeaflet({
      leaflet(options = leafletOptions(minZoom = 8, maxZoom = 13)) |>
        addProviderTiles(providers$CartoDB.Positron) |>
        setView(lng = 151.0, lat = -33.85, zoom = 9)
    })

    observe({
      md <- map_data()
      req(md)
      pal <- pal_fn()

      syd <- md |> filter(lga %in% SYDNEY_LGAS)

      labels <- sprintf(
        "<strong>%s</strong><br/>Rate: %s per 100k<br/>Rank: %s",
        syd$lga,
        fmt_rate(syd$rate_per_100k),
        fmt_rank(syd$rank)
      ) |> lapply(htmltools::HTML)

      leafletProxy("sydney_map", data = syd) |>
        clearShapes() |>
        clearControls() |>
        addPolygons(
          fillColor   = pal(syd$rank),
          weight      = 1,
          opacity     = 1,
          color       = "white",
          fillOpacity = 0.85,
          highlightOptions = highlightOptions(
            weight = 2.5,
            color  = APP_PALETTE$primary,
            fillOpacity = 0.95,
            bringToFront = TRUE
          ),
          label = labels,
          labelOptions = labelOptions(
            style = list("font-weight" = "500", padding = "6px 10px"),
            textsize = "12px"
          ),
          layerId = ~paste0("syd_", lga)
        ) |>
        addLegend(
          position = "bottomright",
          pal      = pal,
          values   = syd$rank,
          title    = "Rank (1 = worst)",
          opacity  = 0.9
        )
    })

    observeEvent(input$sydney_map_shape_click, {
      id <- input$sydney_map_shape_click$id
      if (!is.null(id)) selected_lga(str_remove(id, "^syd_"))
    })

  })
}
