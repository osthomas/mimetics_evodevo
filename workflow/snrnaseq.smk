import pandas as pd
SAMPLES_SN = pd.read_csv("data/snrnaseq/metadata.tsv", sep = "\t").set_index("sample", drop = False)
ALL_SAMPLES_SN = SAMPLES_SN["sample"].unique().tolist()


rule snrnaseq_link:
    input:
        raw = lambda wc: SAMPLES_SN.loc[wc.sample, ["cellranger_raw_h5"]].tolist(),
        filtered = lambda wc: SAMPLES_SN.loc[wc.sample, ["cellranger_filtered_h5"]].tolist()
    output:
        raw = "data/snrnaseq/cellranger_raw/{sample}.h5",
        filtered = "data/snrnaseq/cellranger_filtered/{sample}.h5"
    run:
        os.symlink(input.raw, output.raw)
        os.symlink(input.filtered, output.filtered)


rule cellbender:
    input:
        h5 = "data/snrnaseq/cellranger_raw/{sample}.h5"
    output:
        h5 = "data/snrnaseq/cellbender/{sample}.h5",
        h5_filtered = "data/snrnaseq/cellbender/{sample}_filtered.h5",
    conda: "envs/cellbender.yaml"
    threads: 64
    resources:
        mem_mb = 32 * 1024
    shell:
        """
        # cellbender saves ckpt.tar.gz in the working directory. If multiple
        # jobs are started from the same locations they will clash
        CBTMP="$(mktemp -d)"
        OUTPUT="$(realpath {output.h5})"
        echo "Cellbender tempdir is at $CBTMP" >&2
        pushd "$CBTMP" || exit 1
        cellbender remove-background \\
            --cpu-threads {threads} \\
            --input "{input.h5}" \\
            --output "$OUTPUT" \\
            --expected-cells 20000 \\
            --total-droplets-included 40000
        """


use rule render_qmd as snrnaseq_preproc with:
    input:
        qmd = "analysis/src/snrnaseq_preproc.qmd",
        h5 = expand("data/snrnaseq/cellbender/{sample}_filtered.h5", sample = ALL_SAMPLES_SN),
        tbl_markers = "analysis/output/figures/bulk/tbl_markers.tsv"
    output:
        html = "analysis/output/snrnaseq_preproc.html",
        sce = "pipeline/snrnaseq_preproc.rds"
    conda: "envs/scrnaseq.yaml"
    threads: 8
    resources:
        mem_mb = 32 * 1024


use rule render_qmd as snrnaseq_clustering with:
    input:
        qmd = "analysis/src/snrnaseq_clustering.qmd",
        sce = "pipeline/snrnaseq_preproc.rds"
    output:
        html = "analysis/output/snrnaseq_clustering.html",
        sce = "pipeline/snrnaseq_clustering.rds"
    conda: "envs/scrnaseq.yaml"
    threads: 8
    resources:
        mem_mb = 32 * 1024


use rule render_qmd as snrnaseq_analysis with:
    input:
        qmd = "analysis/src/snrnaseq_analysis.qmd",
        sce = "pipeline/snrnaseq_clustering.rds"
    output:
        html = "analysis/output/snrnaseq_analysis.html",
    conda: "envs/scrnaseq.yaml"
    threads: 8
    resources:
        mem_mb = 32 * 1024
