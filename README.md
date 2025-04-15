# Developmental and Evolutionary Aspects of Mimetic Cells

Michelson et al. (Cell 2022) have identified *thymic mimetic cells* which
express gene signatures similar to those found in peripheral tissues. However,
the developmental dynamics of these mimetic cells are unclear.

Here, we investigated their developmental and evolutionary characteristics.


## Running

Data analysis is implemented as a `snakemake` pipeline.

Environments of individual tools will be installed automatically if
[conda](https://github.com/conda/conda)
or
[mamba](https://github.com/mamba-org/mamba) (recommended, faster) is set up.

After cloning this repository and fetching relevant data from GEO (snRNAseq,
see below) and setting up `snakemake`, the analysis can be
re-run with:

```bash
snakemake --use-conda
```

The `snakemake` version used to run the analysis was `7.22.0`.

Note that some functions, parameters and settings reside in a local `R` package
which is loaded in the individual analyses.


## Output

Analyses produce output under `analysis/output`. Figures are written to
`analysis/output/figures`. The generated file are replicated with numbering as
in the paper in `analysis/output/figures/paper`.


## Data Availability

### Gene Annotation

Gene annotation and orthology information was fetched from Ensembl. The
resulting tables are stored in:

* `pipeline/ensembl_genes_dr.tsv` (D. rerio)
* `pipeline/ensembl_genes_mm.tsv` (M. musculus)


## Gene Signatures

Gene signatures of interest and background signatures are:

* `data/markers/tabula_muris_markers/`, from [Tabula Muris](https://github.com/czbiohub-sf/tabula-muris/tree/master/22_markers)
* `data/markers/michelson_tbls2.csv`, from Michelson et al. 2022
* `data/markers/nusser_progenitor_signatures.csv`, from Nusser et al. 2022
* `data/markers/msigdb_m8.all.v2023.2.Mm.json`, from [MSigDB](https://www.gsea-msigdb.org/gsea/msigdb/mouse/genesets.jsp?collection=M8)
* `data/markers/PanglaoDB_markers_27_Mar_2020.tsv`, from [PanglaoDB](https://panglaodb.se/)

### scRNAseq Data

Raw data from Nusser et al. are deposited in the
[SRA](https://www.ncbi.nlm.nih.gov/Traces/study/?acc=PRJNA418236)
and on
[GEO](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE106856).

These data are included in this repository as `SingleCellExperiment` objects,
saved as `rds`:

* `pipeline/sce_embryo.rds`
* `pipeline/sce_newborn.rds`
* `pipeline/sce_W4BCFEM1.rds`
* `pipeline/sce_W4BCFEM2.rds`
* `pipeline/sce_W4BCMALE.rds`
* `pipeline/sce_W4WTMALE.rds`

Background frequencies for CRISPR/Cas9 scarring are in:

* `data/sc/background.csv`


### Bulk RNAseq Data

Bulk RNAseq data from mouse and zebrafish are deposited on
SRA/GEO:

- [GSE272063](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE272063)
- [GSE272064](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE272064)
- [GSE272144](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE272144)

Counts and metadata are also stored in this repository under
`data/bulk_rnaseq`.


### snRNAseq Data

snRNAseq data from Foxn1 heterozygous and wild type mice are deposited on
SRA/GEO:

- [GSE288957](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE288957)

[CellBender](https://github.com/broadinstitute/CellBender) was used for
background removal. The CellBender output is available in GEO as
`{accession}_cellbender_filtered_{sample}.h5`. The workflow expects these files
at `data/snrnaseq/cellbender/{sample}_filtered.h5`.


### FACS / ISH

Summary statistics from FACS and ISH data are in `data/facs` and `data/ish_counts`.
