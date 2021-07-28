1. The CRAN checks detect an error on Solaris when running the examples, because 
the 'git' command is not found. So I included `if(Sys.which("git") != "")` in 
the examples, to skip them if 'git' is not found.

2. With the new version 0.1.1, the CRAN checks detect an error on Unix systems, 
not on Windows systems. That's because I used `system2` with a file name for 
the argument `stdout` and with `stderr=TRUE`. However, as written in the doc: 
*Because of the way it is implemented, on a Unix-alike `stderr = TRUE` implies 
`stdout = TRUE`*. So I set `stderr = ""`. I tested on a Linux system and it 
works now.

3. The CRAN checks return a NOTE, due to some detritus found. So I changed the 
temporary directory I used to a subdirectory of a "true" R temporary directory.


## Test environments

* local R installation, Windows 10, R 4.1.0
* local R installation, Ubuntu 18.04, R 3.6.3
* win-builder (devel)

## R CMD check results

OK
