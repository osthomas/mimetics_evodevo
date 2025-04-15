get_background_frequency <- function(bcid, background) {
    bg <- background$background_freq
    names(bg) <- background$bcid
    bg <- bg[!is.na(names(bg))]
    bcid_split <- strsplit(bcid, "_")
    res <- sapply(bcid_split, function(x) {
        n_detected <- length(x)
        bc1 <- x[1]
        bc2 <- x[2]
        sfreq <- calc_sfreq(bg[bc1], bg[bc2], n_detected)
        return(sfreq)
    })
    names(res) <- bcid
    return(res)
}


# Calculate the sampling frequency for a pair of barcodes
calc_sfreq <- function(freq_bc1, freq_bc2, n_detected) {
    # Only handled cases: 1 or 2 detected barcodes
    stopifnot(n_detected %in% c(1, 2))
    freqs <- c(freq_bc1, freq_bc2)
    # If a frequency is NA, the barcode was either not detected at all, or is
    # so rare that it did not occur in the bulk -> set to 0
    freqs[is.na(freqs)] <- 0
    if (n_detected == 1) {
        # Detected 1 barcode, the other must be NA, and was thus set to 0.
        # Return the bigger background frequency
        sfreq <- max(freqs, na.rm = TRUE)
    } else if (n_detected == 2) {
        # Detected 2 barcodes.
        # Estimate background frequency based on combination
        sfreq <- 2 * prod(freqs)
    }
    return(sfreq)
}



# Correct p values, but only consider barcodes which actually appeared in the
# data at some point (count > 0)
barcode_p_adj <- function(p, count) {
    stopifnot(length(p) == length(count))
    p[count > 0] <- p.adjust(p[count > 0], method = "BH")
    return(p)
}
