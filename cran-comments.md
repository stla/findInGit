The CRAN checks detect an error on Solaris when running the examples, because 
the 'git' command is not found. So I included `if(Sys.which("git") ! "")` in 
the examples, to skip them if 'git' is not found.


## Test environments

* local R installation, Windows 10, R 4.1.0
* local R installation, Ubuntu 18.04, R 3.6.3
* win-builder (devel)

## R CMD check results

OK
