Environments were originally created by Snakemake from the `*.orig.yaml` specifications.

They were then frozen to maintain versions of implicitly as well as explicitly installed software:

```
snakemake --list-conda-envs

mamba env export -p <PREFIX> > workflow/envs/<env>.yaml
```
