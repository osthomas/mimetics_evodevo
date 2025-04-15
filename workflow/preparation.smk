# Install R packages not available from conda
localrules: install_r_packages
rule install_r_packages:
    input:
        script = "workflow/scripts/install_from_cran.R"
    output: "pipeline/.install_r_packages_done"
    conda: "envs/R.yaml"
    shell:
        """
        Rscript --vanilla "{input.script}" && touch "{output}"
        """


ALL_SC_SAMPLES = [
    "embryo",
    "newborn",
    "W4BCFEM1",
    "W4BCFEM2",
    "W4BCMALE",
    "W4WTMALE"
]

localrules: raceid2sce
rule raceid2sce:
    input:
        markers = "pipeline/markers.rds",
        raceid = "data/sc/{sample}/raceid.rds",
        labels = "data/nusser2022_sc_labels/{sample}_early-late.csv",
        clusters = "data/sc/{sample}/clusters.csv",
        script = "workflow/scripts/raceid2sce.R",
        *rules.install_r_packages.output
    output:
        sce = "pipeline/sce_{sample}.rds"
    conda: "envs/R.yaml"
    shell:
        """
        Rscript --vanilla "{input.script}" \\
            "{input.markers}" \\
            "{input.raceid}" \\
            "{input.labels}" \\
            "{input.clusters}" \\
            "{output.sce}"
        """


use rule render_rmd as markers with:
    input:
        "data/markers/michelson_tbls2.csv",
        "data/markers/nusser_progenitor_signatures.csv",
        "data/markers/msigdb_m8.all.v2023.2.Mm.json",
        "data/markers/PanglaoDB_markers_27_Mar_2020.tsv",
        "data/markers/tabula_muris_markers/",
        **dict(rules.render_rmd.input),
        rmd = "analysis/src/markers.Rmd"
    output:
        html = "analysis/output/markers.html",
        markers = "pipeline/markers.rds",
        markers_collapsed = "pipeline/markers_collapsed.rds",
        markers_mimetics_collapsed = "pipeline/markers_mimetics_collapsed.rds",
        markers_panglao = "pipeline/markers_panglao.rds"
