# Generate rmarkdown/quarto reports

def smkio2rmdparams(wildcards, input, output, which = None):
    """
    Convert snakemake input and output to Rmd params that can be passed via the
    commandline. Inputs are prepended with "input_", outputs with "output_"

    In a rule, use as:
    params:
        rmd_params = smkio2rmdparams

    Parameters
    ----------
    wildcards, input, output: respective snakemake objects
    which : None or List[str]
        Which parameters to pass. If None, pass all. Inclusion is checked AFTER
        prepending "input_" / "output_", thus these prefixes must be included
        in `which`

    Returns
    -------
    String formatted as arguments to a named R list for passing to
    rmarkdown::render
    """
    inputs = []
    outputs = []
    # do not use f strings because snakemake adds spurious whitespace when
    # tokenizing f strings (#2648)
    for k, v in input.items():
        k = "input_" + k
        if which is None or k in which:
            inputs.append("{k}='{v}'".format(k = k, v = v))
    for k, v in output.items():
        k = "output_" + k
        if which is None or k in which:
            outputs.append("{k}='{v}'".format(k = k, v = v))
    return ",".join(inputs + outputs)

rule render_rmd:
    input:
        yaml = "analysis/src/_output.yaml",
        rprofile = ".Rprofile",
        env = "pipeline/.install_r_packages_done"
    resources:
        mem_mb = 1024 * 16
    conda: "envs/R.yaml"
    params:
        rmd_params = ""
    resources:
        mem_mb = 1024 * 16
    shell:
        """
        # If a log file was specified (by a child rule), redirect stderr
        if [[ -n "{log}" ]]; then
            exec 2> "{log}"
        fi

        R_PROFILE_USER="{input.rprofile}"

        output_dir="$(dirname "{output.html}")"
        output_file="$(basename "{output.html}")"
        # Use the absolute path because knitr changes the working directory
        output_yaml="$(realpath "{input.yaml}")"
        Rscript -e "rmarkdown::render(
            '{input.rmd}',
            output_dir = '$output_dir',
            output_file = '$output_file',
            output_yaml = '$output_yaml',
            params = list({params.rmd_params}))"
        """


rule render_qmd:
    # Inheritance: Provide input.qmd and output.html
    params:
        extra = ""
    shell:
        """
        # Make sure quarto sees .Rprofile after changing paths
        export R_PROFILE_USER="$(realpath .Rprofile)"
        # Combining relative paths with embed-resources requires some
        # path gymnastics to separate input and output dirs while keeping
        # quarto happy
        quarto_wd="$(pwd)"
        quarto_indir="$(dirname "{input.qmd}")"
        quarto_infile="$(basename "{input.qmd}")"
        quarto_outfile="$(basename "{input.qmd}").html"
        final_outfile="$(realpath "{output.html}")"

        pushd "$quarto_indir" || exit 1
        quarto render "$quarto_infile" \\
            --execute-dir "$quarto_wd" \\
            --to html \\
            --output "$quarto_outfile" \\
            {params.extra} \\
            --
        mv "$quarto_outfile" "$final_outfile"
        """
