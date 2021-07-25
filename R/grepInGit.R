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
  folder <- file.path(tmpDir, sprintf("_%s_", branch))
  dir.create(folder)
  filenames <- getFilenamesInBranch(branch, ext)
  for(f in filenames){
    args <- sprintf("show %s:./%s", branch, f)
    file <- suppressWarnings(
      system2("git", args, stdout = TRUE, stderr = TRUE)
    )
    path <- file.path(folder, f)
    writeLines(file, path)
  }
  invisible(NULL)
}

getFilesInAllBranches <- function(tmpDir, ext){
  branches <- getBranches()
  for(branch in branches){
    getFilesInBranch(tmpDir, branch, ext)
  }
  invisible(NULL)
}
