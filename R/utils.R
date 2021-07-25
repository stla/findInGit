inSolaris <- function(){
  grepl("sunos", tolower(Sys.info()["sysname"]))
}

isString <- function(x){
  is.character(x) && (length(x) == 1L) && !is.na(x)
}

isBoolean <- function(x){
  is.logical(x) && (length(x) == 1L) && !is.na(x)
}
