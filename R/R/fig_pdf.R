#' Write a plot to a PDF device based on the current knitr chunk options
#'
#' @param outdir Output directory
#' @export
fig_pdf <- function(outdir, p, name = NULL, suffix = NULL) {
    if (is.null(knitr::opts_knit$get("out.format"))) {
        # Bail out early if we are not knitting the document
        invisible(NULL)
    } else {
        w <- knitr::opts_current$get("fig.width")
        h <- knitr::opts_current$get("fig.height")
        if (is.null(name)) {
            name <- knitr::opts_current$get("label")
        }
        if (!is.null(suffix)) {
            name <- paste0(name, suffix)
        }
        if (!dir.exists(outdir)) {
            dir.create(outdir, recursive = TRUE)
        }
        out <- file.path(outdir, paste0(name, ".pdf"))
        pdf(out, width = w, height = h, title = name)
        print(p)
        invisible(dev.off())
    }
}
