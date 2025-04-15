# IO/Reader functions

# Seurat has a function to read CellRanger h5 files, but it chokes on
# CellBender output
# This function is modeled after a code snippet provided by the CellBender
# maintainers:
# https://github.com/broadinstitute/CellBender/issues/66#issuecomment-717575288
# This did not run because the CellBender h5 contains slots that clash with the
# `for genome in genomes` loop.
# The function here is simplified to only support a specific version as
# required. It can read CellRanger and CellBender h5 files that are used in
# the mimetics project.
#' @export
read_h5 <- function(path) {
    h5 <- hdf5r::H5File$new(filename = path, mode = "r")
    counts <- h5[["matrix/data"]]
    indices <- h5[["matrix/indices"]]
    indptr <- h5[["matrix/indptr"]]
    shp <- h5[["matrix/shape"]]
    ft_id <- h5[["matrix/features/id"]][]
    ft_name <- h5[["matrix/features/name"]][]
    barcodes <- h5[["matrix/barcodes"]][]
    mtx <- Matrix::sparseMatrix(
        i = indices[] + 1,
        p = indptr[],
        x = as.numeric(x = counts[]),
        dims = shp[],
        repr = "C"
    )
    rownames(mtx) <- scuttle::uniquifyFeatureNames(ft_id, ft_name)
    colnames(mtx) <- barcodes
    sce <- SingleCellExperiment::SingleCellExperiment(assays = list(counts = mtx))
    rowData(sce)$id <- ft_id
    rowData(sce)$name <- ft_name
    if ("droplet_latents" %in% names(h5)) {
        sce$cell_probability <- h5[["droplet_latents/cell_probability"]][]
    }
    h5$close_all()
    sce
}
