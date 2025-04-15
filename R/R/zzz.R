#' @import ggplot2
.onAttach <- function(libname, pkgname) {
    packageStartupMessage("Package ", pkgname)
    packageStartupMessage("Adjusting plot settings ...")
    # Plot Aesthetics
    if (!interactive()) {
        # Update sizes for paper output that are too small for interactive/screen
        # use
        t <- theme_gray(7) + theme_base + theme_print
        geom_text_size <- 5 / (14 / 5)
        update_geom_defaults("text", list(size = geom_text_size))
        update_geom_defaults("col", list(lwd = 0.3))
        update_geom_defaults("segment", list(lwd = 0.3))
        update_geom_defaults("errorbar", list(lwd = 0.3))
        update_geom_defaults("boxplot", list(lwd = 0.3))
        update_geom_defaults(geomtextpath::GeomTextsegment, list(size = geom_text_size))
        update_geom_defaults(ggrepel::GeomTextRepel, list(size = geom_text_size))
        update_geom_defaults("label", list(size = geom_text_size))
        update_geom_defaults("point", list(size = 0.5, stroke = 0.5))
    } else {
        t <- theme_gray() + theme_base
    }
    theme_set(t)
    options(
        ggplot2.discrete.fill = oi_pal,
        ggplot2.discrete.colour = oi_pal
    )
}
