# Settings for plotting: themes, colors, labels

#' @import ggplot2


theme_base <- theme(
    plot.title = element_text(size = rel(1), face = "bold", hjust = 0.5, margin = margin(0, 0, 1, 0, "pt")),
    axis.text = element_text(color = "black"),
    plot.margin = margin(1, 1, 1, 1, "pt"),
    panel.border = element_rect(fill = NA, color = "black"),
    panel.background = element_rect(fill = NA, color = NA),
    axis.ticks = element_line(color = "black"),
    panel.grid.major.x = element_blank(),
    panel.grid.major.y = element_line(linewidth = 0.1, color = "#EEEEEE"),
    panel.grid.minor = element_blank(),
    strip.background = element_blank(),
    strip.text = element_text(face = "bold", margin = margin(1, 1, 1, 1, "pt")),
    legend.justification.inside = c(1, 1),
    legend.position.inside = c(0.99, 0.99),
    legend.box.spacing = unit(1, "mm"),
    legend.text = element_text(margin = margin(1, 1, 1, 1, "pt")),
    legend.title = element_text(face = "bold", hjust = 0),
    legend.key = element_rect(fill = NA, color = NA),
    legend.key.size = unit(3, "mm")
)


theme_print <- theme(
    legend.spacing.x = unit(0, "mm"),
    legend.key.spacing.y = unit(1, "pt"),
    legend.key.spacing.x = unit(5, "pt")
)


theme_umap <- theme(
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    axis.title = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
)


# Okabe-Ito color palette
oi_pal <- c(
    "#000000",
    "#E69F00",
    "#56B4E9",
    "#009E73",
    "#F0E442",
    "#0072B2",
    "#D55E00",
    "#CC79A7"
)


# Chi6 colors

COL_CHI6 <- c(
    FVB = "black",
    chi6.down = oi_pal[6],
    chi6.up = oi_pal[2]
)


# Population Labels
COL_POPULATION <- c(
    early_progenitor = oi_pal[2],
    postnatal_progenitor = oi_pal[3],
    mTEC = oi_pal[4],
    cTEC = oi_pal[7],
    cTEC_nurse = oi_pal[8],
    unassigned = "gray"
)
COL_POPULATION[1:5] <- colorspace::desaturate(COL_POPULATION[1:5], 0.3)


LBL_SIGNATURE <- c(
    early_progenitor = "Early Progenitor",
    postnatal_progenitor = "Postnatal Progenitor",
    cTEC = "cTEC",
    cTEC_nurse = "cTEC (nurse)",
    mTEC = "mTEC",
    unassigned = "unassigned",
    no_signature = "No signature",
    "Aire-stage" = "Aire-stage",
    Ciliated = "Ciliated",
    Goblet = "Goblet",
    Ionocyte = "Ionocyte",
    Muscle = "Muscle",
    EnteroHepato = "Enterohepatic",
    Lung_basal = "Lung (basal)",
    Microfold = "Microfold",
    Neuroendocrine = "Neuroendocrine",
    Pancreatic = "Pancreatic",
    Skin = "Skin",
    Skin_keratinized = "Skin (keratinized)",
    Skin_basal = "Skin (basal)",
    Tuft = "Tuft",
    Tuft1 = "Tuft1",
    Tuft2 = "Tuft2"
)

# Order for plotting
TEC_SIG_ORDER <- names(LBL_SIGNATURE)


LBL_GROUP <- list(
    E15 = "E15.5",
    cardPos = quote(YFP^{+""}*mCardinal^{+""}),
    cardNeg = quote(YFP^{+""}*mCardinal^{-""}),
    Foxn1het = quote(italic(Foxn1)^{+ "/" - ""}),
    Foxn1KO = quote(italic(Foxn1)^{- "/" - ""}),
    DR.Foxn1KO = quote(italic(foxn1)^{- "/" - ""}),
    DR.WT = quote(italic(foxn1)^{+ "/" +""}),
    Ascl1KO = quote(italic(Ascl1)^{- "/" - ""}*";"*italic(Foxn1)^{+ "/" + ""}),
    Bmp4 = quote(tg*italic(Bmp4)*";"*italic(Foxn1)^{+ "/" + ""}),
    Fgf7wt = quote(tg*italic(Fgf7)*";"*italic(Foxn1)^{+ "/" + ""}),
    Fgf7het = quote(tg*italic(Fgf7)*";"*italic(Foxn1)^{+ "/" - ""}),
    PWK.WT = "PWK",
    CBA.WT = "CBA",
    FVB.WT = "FVB",
    B6.WT = "B6",
    cmF1 = quote(tg*italic(Foxn1)["Cm"]),
    cmF4 = quote(tg*italic(Foxn4)["Cm"]),
    AF4 = quote(tg*italic(Foxn4)["Bl"]),
    cmdtgF1F4 = quote(tg*italic(Foxn1)["Cm"]*";"*tg*italic(Foxn4)["Cm"]),
    chi6.up = quote(Delta*"3ex2 (recovery)"),
    chi6.down = quote(Delta*"3ex2 (collapse)"),
    chi6.unknown = quote(Delta*"3ex2 (unknown)")
)

labeller_group <- function(x) {
    if (x %in% names(LBL_GROUP)) {
        out <- LBL_GROUP[[x]]
    } else {
        out <- x
    }
    out
}

labeller_comparison <- function(x) {
    groups <- strsplit(x, "-vs-")
    groups <- lapply(groups, function(gs) {
        substitute(
            a ~ "vs." ~ b,
            list(
                a = labeller_group(gs[1]),
                b = labeller_group(gs[2])
            )
        )
    })
    return(groups)
}


#' Transform scientific notation (1e-3) to an exponential expression (10^-3)
#' @export
pval_fmt <- function(x, thresh = 0.0001, exact = FALSE) {
    thresh <- 0.0001
    sapply(x, function(x) {
        if (is.na(x)) {
            "n.d."
        } else if (x > thresh) {
            rounded <- DescTools::RoundTo(x, thresh)
            eqsign <- ifelse(rounded == x, "==", "%~~%")
            paste0("p", eqsign, "'", format(x, scientific = FALSE, digits = 1), "'")
        } else if (!exact) {
            x <- log10(x)
            x <- sign(x) * floor(abs(x))
            paste0("p < 10^", x)
        } else {
            rounded <- format(x, scientific = TRUE, digits = 2, nsmall = 2)
            eqsign <- ifelse(rounded == x, "==", "%~~%")
            x <- strsplit(rounded, "e")
            front <- x[[1]][1]
            back <- x[[1]][2]
            paste0("p", eqsign, front, "%*%10^", back)
        }
    })
}
