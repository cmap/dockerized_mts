# dockerized_mts

Dockerized version of the PRISM MTS pipeline. For use with Merino pipeline output or [clue.io](clue.io) datasets.

To get the associated docker image run:
```{bash}
docker pull aboghoss/clue-mts
```

Example command to run the container (see `docker_wrapper.sh`):
```{bash}
bash docker_wrapper.sh -i <INPUT_DIR> -o <OUTPUT_DIR> -p <PROJECT_NAME>
```

Requires the following files in the input data folder:
- PR300 and PR500 Level 2 data (.gctx format)
- PR300 and PR500 cell_info (long table)
- PR300 and PR500 inst_info (long table)
- project_key (long table mapping compounds to projects)

All files other than the Level 2 data can be in any format readable by `data.table::fread`

Testing SCM in jenkins
