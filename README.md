# Small Business Location Engine

Idris Kuti, Gautam Matta, Akash Nikam, Junfei Xia, Chris Walker

You can view the working web app here:
https://team-105-project.shinyapps.io/web-application/

## Description

This is the project repository for Team 105. We built a recommendation engine
which uses real-world business data in the Atlanta Metro area to recommend
suitable locations for small business expansion.

This project is divided into three core parts:
* Data collection
* Model estimation
* Web application

## Installation

Our project is a multi-language, multi-environment process. While you can
install all of the necessary dependencies on your machine, we HIGHLY recommend
visiting the link above. It will take you to our web application without the
need to install anything on your end.

However, if you choose to run the app on your machine, you will need:
* A working Python 3.x installation with:
  * `pandas`
  * `numpy`
  * `sklearn`
  * `jupyter` notebook support
* A working R 4.x (RStudio IDE recommended) installation with:
  * `Rcpp` (Will also install a C++ compiler)
  * `dplyr`
  * `glue`
  * `leaflet`
  * `leaflet.extras`
  * `magrittr`
  * `shiny`

## Execution (Running the App)

If you want to replicate our results (again we HIGHLY recommend the web app
link) you will need to:
* Install RStudio IDE for Windows or Linux
* Open RStudio IDE
* Open the `.Rproj` inside of `CODE/web-application/` to lock working directory
* Ensure all dependencies are installed from CRAN
  * Open `web-application/app.R` 
  * Ensure data, packages, and C++ module are ready
    * for each library run `install.packages("<package name>")` in the console
    * run `library()` calls to ensure libraries are ready
* Run the application by clicking Run App

Note: if R cannot find a file, ensure your working directory is set to
`CODE/web-application` within the repository.

## Components of this Repo

| File/Directory | Description |
| -------------- | ----------- |
| `README.md` | Information about this repo |
| `DOC` | Documentation files for our repository and project |
| `CODE` | Model research and web application code |
