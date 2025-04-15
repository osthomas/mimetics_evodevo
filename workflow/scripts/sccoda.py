#!/usr/bin/env python

# This is closely based on the following references:
# https://pertpy.readthedocs.io/en/latest/tutorials/notebooks/sccoda.html#
# https://pertpy.readthedocs.io/en/latest/tutorials/notebooks/sccoda_extended.html#Using-all-cell-types-as-reference-alternatively-to-reference-selection

import pandas as pd

import scanpy as sc
import pertpy as pt

h5ad = snakemake.input["h5ad"]
adata = sc.read_h5ad(h5ad)
# Keep embryo/newborn/4w
adata = adata[adata.obs["sample"].isin(("embryo", "newborn", "W4WTMALE", "W4BCMALE", "W4BCFEM1", "W4BCFEM2"))]
# Merge "unassigned" annotations
cat_map = {}
for cat in adata.obs["cell_type"].cat.categories:
    if cat.startswith("unassigned"):
        cat_map[cat] = "unassigned"
    else:
        cat_map[cat] = cat
adata.obs["cell_type"] = adata.obs["cell_type"].map(cat_map).astype("category")
cell_types = [
        "early_progenitor", "postnatal_progenitor", "mTEC", "cTEC",
        "Aire-stage", "unassigned"
]

sccoda_model = pt.tl.Sccoda()
sccoda_data = sccoda_model.load(
    adata,
    type="cell_level",
    generate_sample_level=True,
    cell_type_identifier="cell_type",
    sample_identifier="sample",
    covariate_obs=["timepoint"],
)
sccoda_data


# Run scCODA with all major populations as reference cell type
# Set up once to initialize covars - will be replaced in subsequent loop
sccoda_data = sccoda_model.prepare(
    sccoda_data,
    modality_key = "coda",
    formula = "C(timepoint, Treatment(reference='4week'))",
    reference_cell_type = "unassigned"
)
covars = sccoda_data["coda"].uns["scCODA_params"]["covariate_names"]
summaries = {}

for cell_type in cell_types:
    sccoda_data = sccoda_model.prepare(
        sccoda_data,
        modality_key = "coda",
        formula = "C(timepoint, Treatment(reference='4week'))",
        reference_cell_type = cell_type
    )
    sccoda_model.run_nuts(sccoda_data, modality_key="coda", rng_key=1234)
    sccoda_model.set_fdr(sccoda_data, 0.2)
    cred_eff = sccoda_model.credible_effects(sccoda_data, modality_key = "coda")
    summaries[cell_type] = sccoda_model.get_effect_df(sccoda_data, modality_key = "coda")
    summaries[cell_type]["reference"] = cell_type


summary_path = snakemake.output["summary"]
summary = pd.concat(summaries.values()).reset_index()
summary.to_csv(summary_path, index = False)
