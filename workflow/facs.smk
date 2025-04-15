use rule render_rmd as facs with:
    input:
        **dict(rules.render_rmd.input),
        rmd = "analysis/src/facs.Rmd",
        tsv = "data/facs/facs.tsv"
    output:
        html = "analysis/output/facs.html"
