#!/usr/bin/env Rscript

# Install packages from CRAN which are not available via conda/mamba
remotes::install_version("RaceID",
    version = "0.2.8",
    upgrade = "never",
    repos = "http://cran.us.r-project.org")

remotes::install_version("sharp",
    version = "1.4.5",
    upgrade = "never",
    repos = "http://cran.us.r-project.org")
