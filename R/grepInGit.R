isGitRepo <- function(){
  check <- suppressWarnings(
    system2("git", "status", stdout = FALSE, stderr = TRUE)
  )
  is.null(attr(check, "status"))
}

getGitRoot <- function(){
  root <- suppressWarnings(
    system2("git", "rev-parse --show-toplevel", stdout = TRUE, stderr = TRUE)
  )
}

getBranches <- function(){
  # wd <- setwd(path)
  # on.exit(setwd(wd))
  branches <- suppressWarnings(
    system2("git", "branch", stdout = TRUE, stderr = TRUE)
  )
  trimws(sub("^\\*", "", branches), which = "left")
}

getFilenamesInBranch <- function(branch, ext){
  args <- paste0("ls-tree -r --name-only ", branch)
  allFiles <- suppressWarnings(
    system2("git", args, stdout = TRUE, stderr = TRUE)
  )
  allFiles[grep(paste0("\\.", ext, "$"), allFiles)]
}

getFilesInBranch <- function(tmpDir, branch, ext){
  folder <- file.path(tmpDir, sprintf("BRANCH~~%s~~", branch))
  if(dir.exists(folder)){
    unlink(folder, recursive = TRUE, force = TRUE)
  }
  suppressWarnings(dir.create(folder, recursive = TRUE))
  filenames <- getFilenamesInBranch(branch, ext)
  Paths <- NULL
  for(f in filenames){
    args <- sprintf("show %s:./%s", branch, f)
    copyFile <- tempfile(fileext = ".txt")
    file <- suppressWarnings(
      system2("git", args, stdout = copyFile, stderr = "")
    )
    path <- file.path(folder, f)
    Paths <- c(Paths, path)
    branchFolder <- dirname(path)
    if(!dir.exists(branchFolder)){
      dir.create(branchFolder, recursive = TRUE)
    }
    x <- file.rename(from = copyFile, to = path)
    #writeLines(file, path, useBytes = TRUE)
  }
  Paths
}

getFilesInAllBranches <- function(path, ext){
  wd <- setwd(path)
  on.exit(setwd(wd))
  gitRoot <- getGitRoot()
  message("Root git directory: ", gitRoot)
  #setwd(gitRoot)
  tmpDir <- file.path(tempdir(), "gitRepo")
  # if(dir.exists(tmpDir)){
  #   unlink(tmpDir, recursive = TRUE)
  #   tmpDir <- paste0(tempdir(), "_gitRepo")
  # }
  message("Temporary directory: ", tmpDir)
  branches <- getBranches()
  Files <- vector("list", length(branches))
  names(Files) <- branches
  for(branch in branches){
    x <- getFilesInBranch(tmpDir, branch, ext)
    Files[[branch]] <- x
  }
  attr(Files, "tmpDir") <- tmpDir
  Files
}

#' @importFrom stringr str_locate
#' @noRd
grepInGit <- function(
  ext, pattern,
  wholeWord, ignoreCase, perl,
  excludePattern, excludeFoldersPattern,
  directory, output
){
  if(inSolaris()){
    if(Sys.which("ggrep") == ""){
      stop("This package requires the 'ggrep' command-line utility.")
    }
  }else{
    if(Sys.which("grep") == ""){
      stop("This package requires the 'grep' command-line utility.")
    }
  }
  stopifnot(isString(ext))
  stopifnot(isString(pattern))
  stopifnot(isBoolean(wholeWord))
  stopifnot(isBoolean(ignoreCase))
  stopifnot(isBoolean(perl))
  wd <- setwd(directory)
  if(!isGitRepo()){
    setwd(wd)
    stop("Not a git repository", call. = FALSE)
  }
  setwd(wd)
  if(output == "dataframe"){
    opts <- c("--colour=never", "-n", "--with-filename")
  }else{
    opts <- c("--colour=always", "-n", "--with-filename")
  }
  if(wholeWord) opts <- c(opts, "-w")
  if(ignoreCase) opts <- c(opts, "-i")
  if(perl) opts <- c(opts, "-P")
  if(!is.null(excludePattern)){
    stopifnot(isString(excludePattern))
    opts <- c(opts, paste0("--exclude=", shQuote(excludePattern)))
  } #TODO: multiple patterns - https://stackoverflow.com/questions/41702134/grep-exclude-from-how-to-include-multiple-files
  if(!is.null(excludeFoldersPattern)){
    stopifnot(isString(excludeFoldersPattern))
    opts <- c(opts, paste0("--exclude-dir=", shQuote(excludeFoldersPattern)))
  }
  command <- ifelse(inSolaris(), "ggrep", "grep")

  Files <- getFilesInAllBranches(directory, ext)
  if(length(Files) == 0L){
    message(
      sprintf("\nNo file with the extension '%s' has been found.", ext)
    )
    return(invisible(NULL))
  }

  tmpDir <- attr(Files, "tmpDir")
  if(dir.exists(tmpDir)){
    #unlink(tmpDir, recursive = TRUE, force = TRUE)
  }
  #dir.create(tmpDir)
  wd <- setwd(tmpDir)
  on.exit(setwd(wd))
  files <- unlist(Files, use.names = FALSE)
  l <- str_locate(files[1], "BRANCH")[1L, "start"]
  files <- substring(files, l)
  results <- suppressWarnings(system2(
    command,
    args = c(shQuote(pattern), shQuote(files), opts),
    stdout = TRUE, stderr = TRUE
  ))
  if(!is.null(status <- attr(results, "status"))){
    if(status == 1){
      message("No results.")
      return(invisible(NULL))
    }else{
      print(results)
      stop("An error occured. Possibly invalid 'grep' command.")
    }
  }
  results
}
