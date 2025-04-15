# Helper and plotting functions for bulk signature analysis

#' Convert a comparison definition to a contrast for use with limma and camera
#'
#' @param comparison
#'      A comparison definition is a list of character vectors.
#'      names(comparisons) defines a label for the comparison and should include
#'      "-vs-", for example: "KO-vs-WT".
#'
#'      comparison[1] : the variable name defining the groups
#'      comparison[2] : the level for the first group
#'      comparison[3] : the level for the second group
#'      For example, a design ~ 0 + group could work with:
#'
#'      comparison <- c("group", "KO", "WT")
#'
#'      to compare "KO" to "WT", which are both levels in "group".
#' @param design formula object of the underlying design
#'
#' @seealso [limma::makeContrasts()]
comp2contrast <- function(comparison, design) {
    makeContrasts(
        contrasts = paste0(comparison[1], comparison[2:3], collapse = "-"),
        levels = design
    )
}


#' Run cameraPR for one `comparison`
#' @param voom object (EList)
#' @param sets a named list of character vectors, each specifying a set of gene
#'      names (ie., a signature)
#' @param comparison a character vector, see [comp2contrast()]
#' @param lfc LFC threshold, passed to [limma::treat()]
cameraPR_cmp <- function(v, sets, comparison, lfc) {
    ctr <- comp2contrast(comparison, v$design)
    fit <- lmFit(v, v$design)
    trt <- treat(contrasts.fit(fit, ctr), lfc = lfc, robust = TRUE)
    stats <- trt$t
    names(stats) <- rownames(trt)
    res <- cameraPR(
        stats,
        ids2indices(sets, rownames(v))
    )
    res
}


#' Run cameraPR for all `comparisons`
#' @inheritParams cameraPR_cmp
#' @export
run_camera <- function(v, markers, comparisons, lfc) {
    res <- lapply(names(comparisons), function(cmp_name) {
        cmp <- comparisons[[cmp_name]]
        res <- cameraPR_cmp(v, markers, cmp, lfc)
        res <- tibble::rownames_to_column(res, "signature") %>%
            mutate(
                comparison = cmp_name,
                group1 = cmp[2],
                group2 = cmp[3],
                signed.padj.camera = ifelse(
                    Direction == "Down",
                    log10(FDR),
                    -log10(FDR)
                )
            ) %>%
            group_by(Direction) %>%
            mutate(FDR_direction_rank = rank(FDR))
    })
    bind_rows(res)
}


#' Run limma for all `comparisons`
#' @param comparisons a list of character vectors, see [comp2contrast()]
#' @param lfc LFC threshold, passed to [limma::treat()]
#' @export
run_limma <- function(v, comparisons, lfc) {
    fit <- lmFit(v, v$design)
    res <- lapply(names(comparisons), function(cmp_name) {
        cmp <- comparisons[[cmp_name]]
        ctr <- comp2contrast(cmp, v$design)
        res <- treat(contrasts.fit(fit, ctr), lfc = lfc, robust = TRUE)
        res <- topTreat(res, n = Inf)
        res$comparison <- cmp_name
        res$group1 <- cmp[2]
        res$group2 <- cmp[3]
        res <- as_tibble(res, rownames = "gene")
        colnames(res)[colnames(res) %in% c("logFC", "adj.P.Val")] <- c(
            "log2FC",
            "padj"
        )
        res
    })
    bind_rows(res)
}


#' Overall enrichment of signatures in `comparisons`
#' @param dat_camera results from [run_camera()]
#' @param comparisons *Names* of comparisons that were passed to [run_camera()]. These are
#'      plotted, other comparisons are omitted. If NULL, plot all.
#' @param alpha FDR threshold at which to draw a line in the plot
#' @export
plt_camera_overall <- function(dat_camera, comparisons = NULL, alpha) {
    if (!is.null(comparisons)) {
        dat_camera <- filter(dat_camera, comparison %in% comparisons)
    }
    p <- ggplot(
        dat_camera,
        aes(comparison, signed.padj.camera)
    ) +
        geom_point() +
        geom_hline(
            linetype = "33",
            yintercept = log10(alpha) * c(-1, 1)
        ) +
        labs(
            title = "Overall enrichment",
            x = NULL,
            y = expression("signed" ~ ~ log[10] * "(adj. p)"),
        ) +
        theme(
            axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1),
            legend.position = "bottom"
        ) +
        guides(color = guide_legend(override.aes = list(size = 2)))
    p
}


#' Plot most significantly enriched signatures in either direction.
#' @inheritParams plt_camera_overall
#' @param ntop Maximum number of top signatures to show. All must meet `alpha`.
#' @export
plt_camera_top <- function(dat_camera, comparisons = NULL, alpha, ntop) {
    if (!is.null(comparisons)) {
        # Default to all available comparisons
        dat_camera <- filter(dat_camera, comparison %in% comparisons)
    }
    dat_camera <- dat_camera %>%
        filter(FDR_direction_rank <= ntop & FDR <= alpha) %>%
        mutate(signature = forcats::fct_reorder(signature, signed.padj.camera))
    # Find point where direction switches to mark it in the plot
    swap <- dat_camera %>%
        filter(Direction == "Down") %>%
        arrange(desc(signed.padj.camera)) %>%
        slice_head(n = 1)
    p <- ggplot(dat_camera, aes(signed.padj.camera, signature)) +
        geom_vline(xintercept = 0, linewidth = 0.2) +
        geom_hline(
            data = swap,
            linewidth = 0.2,
            aes(
                yintercept = stage(
                    signature,
                    after_scale = as.numeric(yintercept) + 0.5
                )
            )
        ) +
        geom_point() +
        labs(
            x = expression("signed" ~ ~ log[10] * "(adj. p)"),
            y = NULL,
            title = "Most enriched signatures"
        ) +
        theme(axis.text.y = element_text(hjust = 1, size = rel(0.8)))
    p
}


#' Plot camera results with all genes for signatures as a "barcode plot",
#' showing the underlying statistic on which the enrichment score is based.
#' @inheritParams plt_camera_top
#' @inheritParams cameraPR_cmp
#' @export
plt_barcode <- function(
    dat,
    comparisons = NULL,
    sets = NULL,
    dat_camera = NULL
) {
    sets_df <- enframe(sets, "signature", "gene") %>% unnest(gene)
    if (!is.null(comparisons)) {
        dat <- filter(dat, comparison %in% comparisons)
        dat$comparison <- factor(dat$comparison, levels = comparisons)
        dat_camera <- filter(dat_camera, comparison %in% comparisons)
        dat_camera$comparison <- factor(
            dat_camera$comparison,
            levels = comparisons
        )
    }
    if (!is.null(sets)) {
        sets <- names(sets)
        dat_camera <- filter(dat_camera, signature %in% sets)
    }
    d_bg <- dat
    d_bg$signature <- "All Genes"
    d <- left_join(dat, sets_df, by = "gene", relationship = "many-to-many") %>%
        filter(!is.na(signature))
    d <- bind_rows(d_bg, d)
    p <- ggplot(d, aes(t, signature)) +
        geom_segment(
            aes(
                xend = after_stat(x),
                y = stage(signature, after_scale = y - 0.2),
                yend = stage(signature, after_scale = y + 0.2)
            ),
            alpha = 1 / 3
        ) +
        geom_vline(xintercept = 0, color = "red", linewidth = 0.2) +
        scale_y_discrete(name = NULL, limits = rev(c("All Genes", sets))) +
        facet_wrap(~comparison)
    # Add labels from camera if available
    if (!is.null(dat_camera)) {
        dat_camera$t <- 1.2 * min(d$t)
        # Color based on direction as in heatmaps
        cols_dir <- scales::brewer_pal(type = "div")(11)
        p <- p +
            # Dummy data for expansion of panels to fit text
            geom_blank(data = data.frame(t = 1.6 * min(d$t)), aes(y = 1)) +
            geom_text(
                data = dat_camera,
                hjust = 1,
                color = ifelse(
                    dat_camera$signed.padj.camera >= 0,
                    cols_dir[2],
                    cols_dir[length(cols_dir) - 1]
                ),
                aes(label = sprintf("%.1f", signed.padj.camera))
            )
    }
    p
}


#' Plot camera results as a heatmap.
#' @inheritParams plt_barcode
#' @param col_lim limit for the color scale (absolute value, applies to
#'      positive and negative)
#' @export
plt_camera_hm <- function(
    dat_camera,
    comparisons = NULL,
    sets = NULL,
    col_lim = 10
) {
    d <- dat_camera
    if (!is.null(comparisons)) {
        d <- filter(d, comparison %in% comparisons)
    }
    if (!is.null(sets)) {
        d <- filter(d, signature %in% sets)
    }
    p <- ggplot(d, aes(comparison, signature, fill = signed.padj.camera)) +
        geom_tile() +
        scale_fill_distiller(
            type = "div",
            limits = c(-col_lim, col_lim),
            oob = scales::squish,
            breaks = c(-col_lim, 0, col_lim),
            labels = paste(c("<", "", ">"), c(-col_lim, 0, col_lim))
        ) +
        scale_x_discrete(
            limits = comparisons,
            expand = c(0, 0),
        ) +
        scale_y_discrete(
            limits = rev(sets),
            expand = c(0, 0)
        ) +
        labs(
            x = NULL,
            y = NULL,
            fill = expression("signed" ~ ~ log[10] * "(adj. p)")
        ) +
        guides(fill = guide_colorbar(title.position = "left")) +
        theme(
            axis.text.x = element_text(angle = 30, hjust = 1, vjust = 1),
            legend.title = element_text(angle = 90, hjust = 0.5),
            legend.key.height = unit(1, "lines")
        )
    p
}
