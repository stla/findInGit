library(R.utils)
folder1 <- system.file("htmlwidgets", package = "findInGit")
folder2 <- system.file("htmlwidgets", "lib", package = "findInGit")
tmpDir <- paste0(tempdir(), "_gitrepo")
dir.create(tmpDir)
cd <- setwd(tmpDir)
# copy folder1 in 'tmpDir'
copyDirectory(folder1, recursive = FALSE)
# initialize git repo
system("git init")
# add all files to git
system("git add -A")
# commit files
system('git commit -m "mycommit1"')
# create a new branch
system("git checkout -b newbranch")
# copy folder2
copyDirectory(folder2, recursive = FALSE)
# add all files to git
system("git add -A")
# commit files
system('git commit -m "mycommit2"')

# now we can try `findInGit`
findInGit(ext = "js", pattern = "ansi")

# get results in a dataframe:
findInGit(ext = "js", pattern = "ansi", output = "dataframe")

setwd(cd)
unlink(tmpDir, recursive = TRUE, force = TRUE)
