<p align="center">
  <img src="reports/rmarkdown/misc/prism_logo_tagline_side.png" height="80"/>
  <img src="reports/rmarkdown/misc/BroadInstLogoforDigitalRGB.png" height="80"/>
</p>

# MTS Pipeline (with Docker images)

Production version of the [PRISM](https://www.theprismlab.org/) MTS pipeline. For use with Luminex output or [clue.io](clue.io) datasets.

Each module is organized into its own sub-directory with associated Docker images on [Docker Hub](https://hub.docker.com/orgs/prismcmap/repositories). `README` files for each module are contained within their respective directories.

## Pre-requisites

### Docker

In order to run the Docker images (no R installation or local scripts required), install Docker following the instructions [here](https://docs.docker.com/get-docker/).

### R and RStudio (optional)

To run individual scripts or make modifications install [R](https://www.r-project.org/). [RStudio](https://www.rstudio.com/products/rstudio/), an IDE for R, is not required but is recommended for running and viewing R code.

## A note about running locally

The MTS pipeline is run on AWS and therefore most modules are designed with AWS in mind. Some modules are also specifically for handling and moving around files on AWS. Therefore, while the Docker images are useful tools, it may be easier in some cases to run the R scripts individually when running locally
