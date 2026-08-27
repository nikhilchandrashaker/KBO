########################################################################
# KBO Analytics — Team Performance Index Dashboard
#
# Season selector -> team rankings table -> click a team for its
# offense / pitching / percentile breakdown.
#
# Requires: kbo_final.csv (produced by 03_ktpi_leaderboards.R). Put this
# app.R in the same folder as that file and run with shiny::runApp().
########################################################################

library(shiny)
library(tidyverse)
library(DT)

kbo <- read_csv("kbo_final.csv", show_col_types = FALSE) %>%
  mutate(record = paste0(wins, "-", losses))

seasons <- sort(unique(kbo$year), decreasing = TRUE)

# ----------------------------------------------------------------------
# UI
# ----------------------------------------------------------------------
ui <- fluidPage(
  titlePanel("KBO Analytics — Team Performance Index"),

  sidebarLayout(
    sidebarPanel(
      width = 3,
      selectInput("season", "Select a season:", choices = seasons, selected = seasons[1]),
      hr(),
      helpText(
        "KTPI blends each team's offensive and pitching performance ",
        "(standardized within that season) using weights derived from a ",
        "regression of Win% on Offense and Pitching — not an arbitrary 50/50."
      ),
      helpText("Click a row in the table to see that team's full breakdown.")
    ),

    mainPanel(
      width = 9,
      h3("Team Rankings"),
      DTOutput("rankings_table"),
      br(),
      uiOutput("team_detail")
    )
  )
)

# ----------------------------------------------------------------------
# SERVER
# ----------------------------------------------------------------------
server <- function(input, output, session) {

  season_data <- reactive({
    kbo %>%
      filter(year == input$season) %>%
      arrange(desc(KTPI))
  })

  output$rankings_table <- renderDT({
    season_data() %>%
      transmute(
        Team            = team,
        Record          = record,
        `Win%`          = round(win_loss_percentage, 3),
        Offense         = round(Offense_pctile, 1),
        Pitching        = round(Pitching_pctile, 1),
        KTPI            = round(KTPI, 1),
        Balance         = round(Balance, 1)
      ) %>%
      datatable(
        selection = "single",
        rownames  = FALSE,
        options   = list(pageLength = 12, dom = "tp", order = list(list(5, "desc")))
      )
  })

  selected_team <- reactive({
    req(input$rankings_table_rows_selected)
    season_data()[input$rankings_table_rows_selected, ]
  })

  output$team_detail <- renderUI({
    if (is.null(input$rankings_table_rows_selected)) {
      return(div(style = "color: grey;", "Select a team above to see its full breakdown."))
    }

    t <- selected_team()

    tagList(
      h3(paste(t$team, "—", t$year)),

      fluidRow(
        column(
          4,
          h4("Offense"),
          tableOutput_static(list(
            "OPS"        = round(t$OPS, 3),
            "OBP"        = round(t$OBP, 3),
            "SLG"        = round(t$SLG, 3),
            "Runs/game"  = round(t$runs_per_game_bat, 2),
            "Home runs"  = t$homeruns,
            "HR rate"    = paste0(round(t$hr_rate * 100, 1), "%")
          ))
        ),
        column(
          4,
          h4("Pitching"),
          tableOutput_static(list(
            "ERA"                 = round(t$ERA, 2),
            "WHIP"                = round(t$WHIP, 3),
            "K/9"                 = round(t$strikeouts_9, 1),
            "BB/9"                = round(t$walks_9, 1),
            "HR/9"                = round(t$homeruns_9, 1),
            "Runs allowed/game"   = round(t$runs_allowed_per_game, 2)
          ))
        ),
        column(
          4,
          h4("Overall"),
          tableOutput_static(list(
            "KTPI"                  = round(t$KTPI, 1),
            "Offense percentile"    = paste0(round(t$Offense_pctile, 1), "th"),
            "Pitching percentile"   = paste0(round(t$Pitching_pctile, 1), "th"),
            "Balance score"         = round(t$Balance, 1),
            "Record"                = t$record,
            "Win%"                  = round(t$win_loss_percentage, 3)
          ))
        )
      ),

      br(),
      h4("Where this team sits in its league that season"),
      plotOutput("team_scatter", height = "400px")
    )
  })

  # Small helper: render a named list as a simple two-column HTML table
  tableOutput_static <- function(named_list) {
    rows <- imap(named_list, function(val, name) {
      tags$tr(tags$td(tags$b(name)), tags$td(val))
    })
    tags$table(class = "table table-condensed", rows)
  }

  output$team_scatter <- renderPlot({
    t <- selected_team()
    d <- season_data()

    ggplot(d, aes(x = Offense_pctile, y = Pitching_pctile)) +
      geom_point(color = "grey70", size = 2) +
      geom_point(data = t, aes(x = Offense_pctile, y = Pitching_pctile),
                 color = "#C0392B", size = 5) +
      geom_text(data = t, aes(label = team), vjust = -1.3, color = "#C0392B", fontface = "bold") +
      labs(x = "Offense percentile", y = "Pitching percentile") +
      xlim(0, 100) + ylim(0, 100) +
      theme_minimal(base_size = 13)
  })
}

shinyApp(ui, server)
