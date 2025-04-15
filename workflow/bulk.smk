# Only fetch ensembl data if it is not available in the repository
ensembl_tsv = ["pipeline/ensembl_genes_mm.tsv", "pipeline/ensembl_genes_dr.tsv"]
if any([not os.path.exists(f) for f in ensembl_tsv]):
    use rule render_rmd as fetch_ensembl with:
        input:
            **dict(rules.render_rmd.input),
            rmd = ancient("analysis/src/fetch_ensembl.Rmd")
        output:
            html = "analysis/output/fetch_ensembl.html",
            ensembl_mm = "pipeline/ensembl_genes_mm.tsv",
            ensembl_dr = "pipeline/ensembl_genes_dr.tsv"
else:
    rule fetch_ensembl:
        output:
            ensembl_mm = touch("pipeline/ensembl_genes_mm.tsv"),
            ensembl_dr = touch("pipeline/ensembl_genes_dr.tsv")


use rule render_rmd as bulk_rnaseq_preproc with:
    input:
        **dict(rules.render_rmd.input),
        ensembl_mm = rules.fetch_ensembl.output.ensembl_mm,
        rmd = "analysis/src/bulk_rnaseq_preprocess.Rmd",
        markers = rules.markers.output.markers_mimetics_collapsed,
        metadata = [
            "data/bulk_rnaseq/m_musculus/metadata.tsv",
            "data/bulk_rnaseq/d_rerio/metadata.tsv"
        ]
    output:
        html = "analysis/output/bulk_rnaseq_preprocess.html",
        rds = expand(
            "pipeline/{file}.rds",
            file = ["dge_mm", "dge_dr", "v_mm", "v_dr"]
        )
    threads: 8


use rule render_rmd as bulk_rnaseq_limma with:
    input:
        **dict(rules.render_rmd.input),
        ensembl_mm = rules.fetch_ensembl.output.ensembl_mm,
        rmd = "analysis/src/bulk_rnaseq_limma.Rmd",
        rds = rules.bulk_rnaseq_preproc.output.rds
    output:
        html = "analysis/output/bulk_rnaseq_limma.html",
        tbl_markers = "analysis/output/figures/bulk/tbl_markers.tsv"
    threads: 8
