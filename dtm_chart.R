#!/usr/bin/env Rscript
# ==============================================================================
# SLE Disease Trajectory Model Interactive Chart (plotly) — v3
#
# Based on: Goteti et al. 2022, CPT:PSP, doi:10.1002/psp4.12888
#
# History:
#   v1: used subplot() — slider frames were lost during combination
#   v2: unified figure with two x-axes, updated only trace 4 in frames
#       (broken due to plotly.js #4596: unlisted traces become invisible)
#   v3: FIX — include ALL traces in every frame; static traces repeat
#       their data. Bar-only motion is achieved by updating only trace 4's
#       y-value and color, while keeping traces 0-3 and 5 identical.
# ==============================================================================

library(plotly)
library(htmlwidgets)

build_dtm_chart <- function() {

  # ---- Model parameters ----------------------------------------------------
  MU     <- 10
  LAM    <- 0.06
  D_REF   <- -3
  D_HISP  <- -7
  D_OTHER <- -2
  THR     <- 6.5
  SD      <- 3
  TREAT   <- 0.70

  weeks <- c(0, 4, 8, 12, 16, 24, 36, 52)

  traj <- function(t, delta) MU + delta * (1 - exp(-LAM * t))

  # ---- Static trajectory data ----------------------------------------------
  y_ref   <- traj(weeks, D_REF)
  y_hisp  <- traj(weeks, D_HISP)
  y_other <- traj(weeks, D_OTHER)
  y_thr   <- rep(THR, length(weeks))

  # ---- Response rate model -------------------------------------------------
  R_REF   <- pnorm((THR - traj(52, D_REF))   / SD)
  R_HISP  <- pnorm((THR - traj(52, D_HISP))  / SD)
  R_OTHER <- pnorm((THR - traj(52, D_OTHER)) / SD)

  enrollment_grid <- seq(0, 60, by = 5)

  compute_pr <- function(f_hisp_pct) {
    f_h <- f_hisp_pct / 100
    f_o <- 0.20
    f_r <- pmax(0, 1 - f_h - f_o)
    f_h * R_HISP + f_o * R_OTHER + f_r * R_REF
  }

  placebo_rates  <- vapply(enrollment_grid, compute_pr, numeric(1))
  treatment_gaps <- TREAT - placebo_rates

  get_verdict <- function(gap) {
    if (gap >= 0.20) list(color = "#1D9E75", text = "有意差あり ✓")
    else if (gap >= 0.08) list(color = "#BA7517", text = "境界域 △")
    else list(color = "#A32D2D", text = "有意差なし ✗")
  }

  # ---- Colors --------------------------------------------------------------
  color_ref   <- "#888780"
  color_hisp  <- "#1D9E75"
  color_other <- "#D85A30"
  color_thr   <- "#3788dd"
  color_treat <- "#3788dd"

  # ---- Initial state (matches original default of 20%) ---------------------
  init_idx <- which(enrollment_grid == 15) #20)
  init_pr  <- placebo_rates[init_idx]
  init_gap <- treatment_gaps[init_idx]
  init_v   <- get_verdict(init_gap)

  # ==========================================================================
  # Build initial figure — six traces total
  # ==========================================================================
  fig <- plot_ly()

  # Trace 0: Non-Hispanic (static, left panel)
  fig <- fig %>% add_trace(
    x = weeks, y = y_ref,
    type = "scatter", mode = "lines+markers",
    name = "Non-Hispanic (参照)",
    line = list(color = color_ref, width = 2),
    marker = list(color = color_ref, size = 8),
    xaxis = "x", yaxis = "y",
    hovertemplate = "Week %{x}<br>θ = %{y:.2f}<extra>Non-Hispanic</extra>"
  )

  # Trace 1: Hispanic C/S America (static, left panel)
  fig <- fig %>% add_trace(
    x = weeks, y = y_hisp,
    type = "scatter", mode = "lines+markers",
    name = "Hispanic C/S America",
    line = list(color = color_hisp, width = 2.5, dash = "dash"),
    marker = list(color = color_hisp, size = 8),
    xaxis = "x", yaxis = "y",
    hovertemplate = "Week %{x}<br>θ = %{y:.2f}<extra>Hispanic C/S</extra>"
  )

  # Trace 2: Race = Other (static, left panel)
  fig <- fig %>% add_trace(
    x = weeks, y = y_other,
    type = "scatter", mode = "lines+markers",
    name = "Race = Other",
    line = list(color = color_other, width = 2, dash = "dot"),
    marker = list(color = color_other, size = 8),
    xaxis = "x", yaxis = "y",
    hovertemplate = "Week %{x}<br>θ = %{y:.2f}<extra>Race = Other</extra>"
  )

  # Trace 3: Response threshold (static, left panel)
  fig <- fig %>% add_trace(
    x = weeks, y = y_thr,
    type = "scatter", mode = "lines",
    name = "応答閾値 (例示)",
    line = list(color = color_thr, width = 1.5, dash = "dashdot"),
    xaxis = "x", yaxis = "y",
    hoverinfo = "skip"
  )

  # Trace 4: Placebo bar (dynamic, right panel)
  fig <- fig %>% add_trace(
    x = c("プラセボ群"),
    y = c(init_pr),
    type = "bar",
    name = "プラセボ群",
    marker = list(color = init_v$color),
    text = sprintf("%.0f%%", init_pr * 100),
    textposition = "outside",
    textfont = list(size = 16),
    xaxis = "x2", yaxis = "y2",
    showlegend = FALSE,
    hovertemplate = "プラセボ群<br>応答率: %{y:.1%}<extra></extra>"
  )

  # Trace 5: Treatment bar (static content, right panel)
  fig <- fig %>% add_trace(
    x = c("治療群"),
    y = c(TREAT),
    type = "bar",
    name = "治療群",
    marker = list(color = color_treat),
    text = sprintf("%.0f%%", TREAT * 100),
    textposition = "outside",
    textfont = list(size = 16),
    xaxis = "x2", yaxis = "y2",
    showlegend = FALSE,
    hovertemplate = "治療群<br>応答率: %{y:.1%}<extra></extra>"
  )

  # ==========================================================================
  # Layout — two panels side by side, no subplot()
  # ==========================================================================
  fig <- fig %>% layout(
    title = list(
      text = "<b>SLE Disease Trajectory Model — 地域差と試験結果への影響</b>",
      font = list(size = 15),
      x = 0.5
    ),
    xaxis = list(
      domain = c(0.00, 0.45), #0.55),
      title = "試験週数",
      gridcolor = "rgba(0,0,0,0.06)",
      zeroline = FALSE,
      anchor = "y"
    ),
    yaxis = list(
      domain = c(0, 1),
      title = "潜在疾患活動性 (高値 = 重症)",
      range = c(2, 11),
      gridcolor = "rgba(0,0,0,0.06)",
      zeroline = FALSE,
      anchor = "x"
    ),
    xaxis2 = list(
      domain = c(0.68, 1.00),
      anchor = "y2",
      showgrid = FALSE
    ),
    yaxis2 = list(
      domain = c(0, 1),
      title = "応答率",
      range = c(0, 0.9),
      tickformat = ".0%",
      gridcolor = "rgba(0,0,0,0.06)",
      anchor = "x2"
    ),
    # legend = list(
    #   orientation = "h",
    #   x = 0.25, xanchor = "center",
    #   y = -0.15
    # ),
    legend = list(
      orientation = "v",
      x = 0.46, xanchor = "left",
      y = 0.5, yanchor = "middle",
      font = list(size = 11),
      bgcolor = "rgba(255,255,255,0.8)"
    ),
    # margin = list(l = 60, r = 30, t = 100, b = 130),
    margin = list(l = 60, r = 30, t = 60, b = 90),
    plot_bgcolor = "white",
    paper_bgcolor = "white",
    annotations = list(
      list(
        x = 0.84, y = 1.05, xref = "paper", yref = "paper",
        text = sprintf(
          "<b>治療効果: %+.0f pt &nbsp;|&nbsp; <span style='color:%s'>%s</span></b>",
          init_gap * 100, init_v$color, init_v$text
        ),
        showarrow = FALSE,
        font = list(size = 13)
      )
    )
  )

  # ==========================================================================
  # Frames — CRITICAL FIX
  #
  # Every frame MUST include data for all 6 traces (0-5), otherwise
  # plotly.js will hide the unlisted traces (see plotly.js issue #4596).
  # Static traces repeat their original data; the placebo bar (trace 4)
  # is the only one that actually changes across frames.
  # ==========================================================================
  frames_list <- lapply(seq_along(enrollment_grid), function(i) {
    pct <- enrollment_grid[i]
    pr  <- placebo_rates[i]
    gap <- treatment_gaps[i]
    v   <- get_verdict(gap)

    list(
      name = as.character(pct),
      data = list(
        # Trace 0: Non-Hispanic (repeat static data)
        list(
          x = weeks, y = y_ref,
          type = "scatter", mode = "lines+markers",
          line = list(color = color_ref, width = 2),
          marker = list(color = color_ref, size = 8)
        ),
        # Trace 1: Hispanic C/S America
        list(
          x = weeks, y = y_hisp,
          type = "scatter", mode = "lines+markers",
          line = list(color = color_hisp, width = 2.5, dash = "dash"),
          marker = list(color = color_hisp, size = 8)
        ),
        # Trace 2: Race = Other
        list(
          x = weeks, y = y_other,
          type = "scatter", mode = "lines+markers",
          line = list(color = color_other, width = 2, dash = "dot"),
          marker = list(color = color_other, size = 8)
        ),
        # Trace 3: Response threshold
        list(
          x = weeks, y = y_thr,
          type = "scatter", mode = "lines",
          line = list(color = color_thr, width = 1.5, dash = "dashdot")
        ),
        # Trace 4: Placebo bar (DYNAMIC — this is what changes)
        list(
          x = list("プラセボ群"),
          y = list(pr),
          type = "bar",
          marker = list(color = v$color),
          text = list(sprintf("%.0f%%", pr * 100)),
          textposition = "outside",
          textfont = list(size = 16)
        ),
        # Trace 5: Treatment bar (repeat static data)
        list(
          x = list("治療群"),
          y = list(TREAT),
          type = "bar",
          marker = list(color = color_treat),
          text = list(sprintf("%.0f%%", TREAT * 100)),
          textposition = "outside",
          textfont = list(size = 16)
        )
      ),
      # List all 6 trace indices (0-indexed) so none disappear
      traces = list(0, 1, 2, 3, 4, 5),
      layout = list(
        annotations = list(
          list(
            x = 0.84, y = 1.05, xref = "paper", yref = "paper",
            text = sprintf(
              "<b>治療効果: %+.0f pt &nbsp;|&nbsp; <span style='color:%s'>%s</span></b>",
              gap * 100, v$color, v$text
            ),
            showarrow = FALSE,
            font = list(size = 13)
          )
        )
      )
    )
  })

  # Attach frames at the figure level
  fig$x$frames <- frames_list

  # ==========================================================================
  # Slider
  # ==========================================================================
  slider_steps <- lapply(seq_along(enrollment_grid), function(i) {
    list(
      method = "animate",
      label  = as.character(enrollment_grid[i]),
      args   = list(
        list(as.character(enrollment_grid[i])),
        list(
          mode = "immediate",
          frame = list(duration = 200, redraw = TRUE),
          transition = list(duration = 150)
        )
      )
    )
  })

  fig <- fig %>% layout(
    sliders = list(
      list(
        active = init_idx - 1,
        currentvalue = list(
          prefix = "Hispanic C/S America 組み入れ比率: ",
          suffix = "%",
          font = list(size = 13, color = "#333"),
          xanchor = "left"
        ),
        pad = list(t = 50, b = 10),
        len = 0.9,
        x = 0.05,
        y = -0.02,
        steps = slider_steps
      )
    )
  )

  return(fig)
}
# end build_dtm_chart() =======================================================


# ==============================================================================
# Standalone HTML export
# ==============================================================================
if (sys.nframe() == 0L) {
  combined <- build_dtm_chart()

  outfile <- "dtm_interactive.html"

  saveWidget(
    combined,
    file          = outfile,
    selfcontained = TRUE,
    title         = "SLE DTM Interactive Chart"
  )

  cat("Output saved to:", outfile, "\n")
  cat("File size:", round(file.info(outfile)$size / 1024, 1), "KB\n")
}

# ==============================================================================
# Usage from a Quarto chunk
# ==============================================================================
# ```{r}
# source("dtm_chart.R")
# build_dtm_chart()
# ```
