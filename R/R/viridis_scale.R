#' Viridis scale for ComplexHeatmap
viridis_scale <- function(low = NULL, high = NULL) {
    if (!(is.null(low) && is.null(high))) {
        col <- circlize::colorRamp2(
            breaks = seq(low, high, length.out = 256),
            colors = viridis::viridis(256)
        )
    } else {
        col <- viridis::viridis(256)
    }
    return(col)
}
