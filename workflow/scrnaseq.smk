rule zellkonverter:
    input:
        rds = "pipeline/{sce}.rds"
    output:
        h5ad = "pipeline/{sce}.h5ad"
    conda:
        "envs/zellkonverter.yaml"
    script:
        "scripts/zellkonverter.R"


use rule render_rmd as data_integration with:
    input:
        expand("pipeline/sce_{sample}.rds", sample = ALL_SC_SAMPLES),
        **dict(rules.render_rmd.input),
        rmd = "analysis/src/data_integration.Rmd"
    output:
        html = "analysis/output/data_integration_{which}.html",
        sce = "pipeline/integrated_{which}/sce_integrated.rds"
    params:
        # use path concatenation because snakemake adds spurious whitespace
        # around f strings (#2648)
        rmd_params = lambda wc, output: "universe = " + {"universe": "TRUE", "all": "FALSE"}[wc.which] + ", sce_out = '" + output.sce + "'"


use rule render_rmd as identify_mimetics with:
    input:
        **dict(rules.render_rmd.input),
        markers = rules.markers.output.markers,
        sce_universe = "pipeline/integrated_universe/sce_integrated.rds",
        sce_all = "pipeline/integrated_all/sce_integrated.rds",
        rmd = "analysis/src/identify_mimetics.Rmd"
    output:
        sce_universe = "pipeline/integrated_universe/sce_integrated_mimetics.rds",
        sce_all = "pipeline/integrated_all/sce_integrated_mimetics.rds",
        tbl = "pipeline/integrated_universe/aucell_mimetics_tbl.rds",
        html = "analysis/output/identify_mimetics.html"
    params:
        rmd_params = lambda wc, input, output: smkio2rmdparams(wc, input, output, which = ["input_markers", "input_sce_universe", "input_sce_all", "output_sce_universe", "output_sce_all", "output_tbl"])


use rule render_rmd as barcodes_for_groups with:
    input:
        sce = rules.identify_mimetics.output.sce_universe,
        **dict(rules.render_rmd.input),
        bg = "data/sc/background.csv",
        rmd = "analysis/src/barcodes_for_groups.Rmd"
    output:
        html = "analysis/output/barcodes_for_groups.html"


# Generates final figures
use rule render_rmd as scrnaseq with:
    input:
        **dict(rules.render_rmd.input),
        ensembl_mm = rules.fetch_ensembl.output.ensembl_mm,
        rmd = "analysis/src/scrnaseq.Rmd",
        rds = "pipeline/integrated_universe/sce_integrated_mimetics.rds",
        tbl = "pipeline/integrated_universe/aucell_mimetics_tbl.rds"
    output:
        html = "analysis/output/scrnaseq.html"
    threads: 8


rule sccoda:
    input:
        h5ad = "pipeline/integrated_universe/sce_integrated_mimetics.h5ad"
    output:
        summary = "pipeline/sccoda_summary.csv"
    conda:
        "envs/sccoda.yaml"
    script:
        "scripts/sccoda.py"


use rule render_rmd as sccoda_rmd with:
    input:
        **dict(rules.render_rmd.input),
        rmd = "analysis/src/sccoda.Rmd",
        summary = "pipeline/sccoda_summary.csv"
    output:
        html = "analysis/output/sccoda.html"


localrules: copy_qmd
rule copy_qmd:
    input: "analysis/src/cellrank.qmd"
    output: temp("analysis/src/cellrank_{variant}.qmd")
    shell:
        """
        cp "{input}" "{output}"
        """


use rule render_qmd as cellrank with:
    input:
        qmd = "analysis/src/cellrank_{variant}.qmd",
        h5ad = "pipeline/integrated_all/sce_integrated_mimetics.h5ad",
    output:
        html = "analysis/output/cellrank_{variant}.html",
    conda: "envs/scrnaseq.yaml"
    params:
        extra = lambda wc: "-P variant:" + wc.variant
