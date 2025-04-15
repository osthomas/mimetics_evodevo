# Wrappers and settings for running AUCell

#' @export
AUCELL_MAX_RANK <- 600

#' @export
THRESHOLDS_MIMETICS <- c(
    "Aire-stage" = 0.32,
    "Ciliated" = 0.11,
    "EnteroHepato" = 0.3,
    "Goblet" = 0.23,
    "Ionocyte" = 0.135,
    "Lung_basal" = 0.3,
    "Microfold" = 0.3,
    "Muscle" = 0.4,
    "Neuroendocrine" = 0.12,
    "Pancreatic" = 0.18,
    "Skin_basal" = 0.22,
    "Skin_keratinized" = 0.2,
    "Tuft1" = 0.12,
    "Tuft2" = 0.19
)


rank_signatures <- function(dat) {
    dat %>%
    dplyr::group_by(signature) %>%
    dplyr::mutate(
        auc_zscore = as.numeric(scale(auc)),
        # Rank of the cell within the signature (higher rank = further
        # right on the histogram)
        auc_signature_rank = rank(auc),
    ) %>%
    dplyr::group_by(transcriptome) %>%
    dplyr::mutate(
        # Rank of the signature within the cell
        auc_cell_rank = rank(auc_zscore),
        above_threshold = auc >= threshold,
        thresholds_reached = sum(above_threshold),
        # Prevent duplicate assignment
        # First take the signature in which the cell is furthest to the right
        # in the histogram
        # If there are ties, take the highest-scoring signature for this cell
        # order(order(...)) can be used to rank on multiple columns, but then
        # the ranks go from lowest (= best) to highest (= worst). rank() is the
        # other way  around by default!
        assignment_rank = order(
            order(
                above_threshold,
                auc_signature_rank,
                auc_cell_rank,
                decreasing = TRUE
            )
        ),
        assigned = above_threshold & assignment_rank == min(assignment_rank)
    ) %>%
    dplyr::ungroup()
}

#' @export
run_aucell <- function(sce, markers, max_rank, thresholds) {
    # Identify mimetic cells using AUCell
    # See also:
    # https://bioconductor.org/books/3.16/OSCA.basic/cell-type-annotation.html#assigning-cell-labels-from-gene-sets
    set.seed(111)
    rankings <- AUCell::AUCell_buildRankings(counts(sce), plotStats = FALSE)
    print(rankings)
    aucs <- AUCell::AUCell_calcAUC(markers, rankings, aucMaxRank = max_rank)
    colData(sce)$signature <- NULL
    # Use default thresholds for unprovided
    missing_thresh <- !(names(markers) %in% names(thresholds))
    if (any(missing_thresh)) {
        missing_thresh <- names(markers)[missing_thresh]
        warning("Missing thresholds: ", paste0(missing_thresh, collapse = ", "))
        thresholds[missing_thresh] <- 0.1
    }
    thresholds <- thresholds[names(markers)]

    # Combine AUCs and thresholds in a tidy tibble
    tbl_aucs <- assay(aucs) %>%
        tibble::as_tibble(rownames = "signature") %>%
        tidyr::pivot_longer(-signature, names_to = "transcriptome", values_to = "auc")
    tbl_setsize <- lapply(markers, length) %>%
        unlist() %>%
        tibble::enframe(name = "signature", value = "n_genes")
    tbl_thresholds <- thresholds %>%
        tibble::enframe(name = "signature", value = "threshold") %>%
        dplyr::left_join(tbl_setsize)
    tbl_signatures <- Reduce(left_join, list(tbl_aucs, tbl_thresholds, tbl_setsize)) %>%
        dplyr::left_join(as.data.frame(colData(sce))) %>%
        rank_signatures()
    tbl_assigned <- tbl_signatures %>% filter(assigned)

    # Add the assignments to the sce object
    # Use dplyr left_join, because base::merge does not preserve row order and
    # SingleCellExperiment relies on it
    colData(sce) <- as.data.frame(colData(sce)) %>%
        dplyr::left_join(tbl_assigned[, c("transcriptome", "signature", "auc")]) %>%
        dplyr::mutate(
            signature = ifelse(is.na(signature), "no_signature", as.character(signature)),
            # Make signature a factor with all *identified* signatures
            signature = factor(signature),
            signature = droplevels(signature),
            rownames = transcriptome
        ) %>%
        tibble::column_to_rownames("rownames") %>%
        DataFrame()
    res <- list(sce = sce, tbl = tbl_signatures)
    return(res)
}


#' @export
plt_aucell_jaccard <- function(auc_tbl) {
    auc_over <- filter(auc_tbl, above_threshold) %>%
        group_by(signature) %>%
        summarize(cells = list(transcriptome))
    auc_grid1 <- auc_over[c("signature", "cells")]
    auc_grid2 <- auc_over[c("signature", "cells")]
    colnames(auc_grid1) <- paste(colnames(auc_grid1), "x", sep = ".")
    colnames(auc_grid2) <- paste(colnames(auc_grid2), "y", sep = ".")
    jaccard <- function(x, y) {
        length(intersect(x, y)) / length(union(x, y))
    }
    auc_grid <- expand_grid(
        signature.x = auc_over$signature,
        signature.y = auc_over$signature
    )
    auc_grid <- auc_grid %>%
        left_join(auc_grid1) %>%
        left_join(auc_grid2) %>%
        mutate(jaccard = purrr::pmap_dbl(list(cells.x, cells.y), jaccard))
    p_jaccard <- ggplot(auc_grid, aes(signature.x, signature.y, fill = jaccard)) +
        geom_tile() +
        scale_fill_viridis_c(limits = c(0, 1)) +
        labs(x = NULL, y = NULL, fill = "Jaccard\n(cells over threshold)") +
        theme(
            axis.text.x = element_text(angle = 30, hjust = 1, vjust = 1)
        )
    p_jaccard
}
