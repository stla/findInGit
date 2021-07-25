library(findInGit)
library(R.utils) # to use the `copyDirectory` function
folder1 <- system.file("htmlwidgets", package = "findInGit")
folder2 <- system.file("htmlwidgets", "lib", package = "findInGit")
tmpDir <- paste0(tempdir(), "_gitrepo")
dir.create(tmpDir)
# set tmpDir as the working directory
cd <- setwd(tmpDir)
# copy folder1 in tmpDir
copyDirectory(folder1, recursive = FALSE)
# initialize git repo
system("git init")
# add all files to git
system("git add -A")
# commit files
system('git commit -m "mycommit1"')
# create a new branch
system("git checkout -b newbranch")
# copy folder2 in tmpDir, under the new branch
copyDirectory(folder2, recursive = FALSE)
# add all files to git
system("git add -A")
# commit files
system('git commit -m "mycommit2"')

# now we can try `findInGit`
findInGit(ext = "js", pattern = "ansi")

# get results in a dataframe:
findInGit(ext = "js", pattern = "ansi", output = "dataframe")

# one can also get the widget and the dataframe:
fig <- findInGit(ext = "css", pattern = "color", output = "viewer+dataframe")
fig
FIG2dataframe(fig)

# return to initial current directory
setwd(cd)
# delete tmpDir
unlink(tmpDir, recursive = TRUE, force = TRUE)
