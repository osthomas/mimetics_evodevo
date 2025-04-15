#!/usr/bin/env Rscript

library(S4Vectors)  # for metadata()
sce <- readRDS(snakemake@input[["rds"]])
# Cannot convert functions
metadata(sce)[sapply(metadata(sce), is, "function")] <- NULL
zellkonverter::writeH5AD(sce, snakemake@output[["h5ad"]])
