isGitRepo <- function(){
  # folders <- list.dirs(path, recursive = FALSE, full.names = FALSE)
  # wd <- setwd(path)
  # on.exit(setwd(wd))
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
  folder <- file.path(tmpDir, sprintf("BRANCH__%s__", branch))
  dir.create(folder)
  filenames <- getFilenamesInBranch(branch, ext)
  Paths <- NULL
  for(f in filenames){
    args <- sprintf("show %s:./%s", branch, f)
    file <- suppressWarnings(
      system2("git", args, stdout = TRUE, stderr = TRUE)
    )
    path <- file.path(folder, f)
    Paths <- c(Paths, path)
    branchFolder <- dirname(path)
    if(!dir.exists(branchFolder)){
      dir.create(branchFolder, recursive = TRUE)
    }
    writeLines(file, path)
  }
  Paths
}

getFilesInAllBranches <- function(path, ext){
  wd <- setwd(path)
  on.exit(setwd(wd))
  gitRoot <- getGitRoot()
  setwd(gitRoot)
  tmpDir <- tempdir()
  cat("tmpDir:\n")
  print(tmpDir)
  branches <- getBranches()
  Files <- vector("list", length(branches))
  names(Files) <- branches
  for(branch in branches){
    x <- getFilesInBranch(tmpDir, branch, ext)
    Files[[branch]] <- x
  }
  Files
}
