StatSummaryPanel <- ggplot2::ggproto("StatSummaryPanel", ggplot2::Stat,
    compute_panel = function(data, scales, fun) {
        fun(data)
  },
  required_aes = ""
)

#' A stat layer for ggplot2 that allows calculation of summary statistics per
#' panel, with access to the whole data.
#' export
stat_summary_panel <- function(mapping = NULL, data = NULL, geom = "point",
    position = "identity", na.rm = FALSE, show.legend = NA,
    inherit.aes = TRUE, ...) {
    ggplot2::layer(
        stat = StatSummaryPanel, data = data, mapping = mapping, geom = geom,
        position = position, show.legend = show.legend, inherit.aes = inherit.aes,
        params = list(na.rm = na.rm, ...)
    )
}
