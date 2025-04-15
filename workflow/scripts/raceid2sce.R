#!/usr/bin/env Rscript

# Convert RaceID objects to SingleCellExperiment objects
# USAGE:
# raceid2sce.R markers.rds raceid.rds clusterlabels.csv clusters.csv output.rds
# markers.rds is a path to a .rds file storing a list() of character vectors,
# each holding signature genes for a signature. These genes will be retained in
# the output even if the are among RaceID's filtered genes (FGenes)
# raceid.rds is a path to a .rds file storing a RaceID object
# clusterlabels.csv is a csv with three columns:
#   cluster - RaceID cluster ID
#   label - label of the cluster in the original analysis
#   label_fine - label of the cluster in the original analysis, with
#   'unassigned' clusters further subdivided by their proximity to known
#   clusters
# clusters.csv is a csv with previously extraced cluster information and
# metadata
# output.rds is a path to a .rds file storing the converted
# SingleCellExperiment object

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 5) {
    stop("Expected exactly 5 arguments!")
}

markers_path <- args[[1]]
raceid_path <- args[[2]]
labels_path <- args[[3]]
clusters_path <- args[[4]]
sce_path <- args[[5]]

suppressPackageStartupMessages({
    library(dplyr)
    library(SingleCellExperiment)
})

# Get required genes of interest from markers list
markers <- readRDS(markers_path)
goi <- unique(unlist(markers))

# Read cluster data and labels
cluster_data <- read.csv(clusters_path)
cluster_labels <- read.csv(labels_path)
# Do not allow any NAs
stopifnot(!any(is.na(cluster_labels)))
# Enfore presence of all cluster in label file
missing_labels <- setdiff(cluster_data$cluster, cluster_labels$cluster)
missing_data <- setdiff(cluster_labels$cluster, cluster_data$cluster)
if (length(missing_labels) > 0 || length(missing_data) > 0) {
    msg <- sprintf(
        "Cluster in data and labels do not agree:\nMissing in labels: %s\nMissing in data:%s",
        paste0(missing_labels, collapse = ","),
        paste0(missing_data, collapse = ",")
    )
    stop(msg)
}
cluster_data <- left_join(cluster_data, cluster_labels)

# Extract data from RaceID object
raceid <- readRDS(raceid_path)
# Get counts of genes. Omit explicitly filtered genes, but explicitly include
# mimetic genes, even if implicitly filtered (eg. by correlation), provided
# they're in the data
goi_here <- goi[!(goi %in% c(raceid@filterpar$CGenes, raceid@filterpar$FGenes))]
goi_here <- goi[goi %in% rownames(raceid@ndata)]
genes <- unique(c(raceid@genes, goi_here))
expdata <- as.matrix(raceid@expdata)[genes, cluster_data$transcriptome]
ndata <- as.matrix(raceid@ndata)[genes, cluster_data$transcriptome]

# Convert to SingleCellExperiment
coldata <- cluster_data
if (!"bcid" %in% colnames(coldata)) {
    coldata$bcid <- NA
}

rownames(coldata) <- coldata$transcriptome
# some rows are "NA" for sample
have_samples <- unique(coldata$sample[!is.na(coldata$sample)])
stopifnot(length(have_samples) == 1)
coldata$sample <- have_samples
# Order
expdata <- expdata[, coldata$transcriptome]
ndata <- ndata[, coldata$transcriptome]
sce <- SingleCellExperiment(
    assays = list(
        counts = expdata,
        logcounts = log2(ndata * 10000 + 1)
    ),
    colData = coldata[, c("transcriptome", "sample", "barcoded", "genotype", "timepoint", "cluster", "label", "label_fine", "bcid")])
# Maintain original RaceID UMAPs
umap <- as.matrix(coldata[, c("umap1", "umap2")])
rownames(umap) <- coldata$transcriptome
reducedDim(sce, "UMAP") <- umap

saveRDS(sce, sce_path)
