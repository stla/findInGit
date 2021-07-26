#' Find pattern in files of a 'git' repository
#' @description Find a pattern in the files with a given extension, in all
#'   branches of a 'git' repository.
#'
#' @param ext file extension, e.g. \code{"R"} or \code{"js"}
#' @param pattern pattern to search for, a regular expression, e.g.
#'   \code{"function"} or \code{"^function"}
#' @param wholeWord logical, whether to match the whole pattern
#' @param ignoreCase logical, whether to ignore the case
#' @param perl logical, whether \code{pattern} is a Perl regular expression
#' @param excludePattern a pattern; exclude from search the files and folders
#'   which match this pattern
#' @param excludeFoldersPattern a pattern; exclude from search the folders
#'   which match this pattern
#' @param root path to the root directory to search from
#' @param output one of \code{"viewer"}, \code{"dataframe"} or
#'   \code{"viewer+dataframe"}; see examples
#'
#' @return A dataframe if \code{output="dataframe"}, otherwise a
#'   \code{htmlwidget} object.
#'
#' @import htmlwidgets
#' @importFrom stringr str_split_fixed str_remove str_replace
#' @importFrom crayon strip_style
#' @export
#'
#' @examples library(findInGit)
#' library(R.utils) # to use the `copyDirectory` function
#' folder1 <- system.file("htmlwidgets", package = "findInGit")
#' folder2 <- system.file("htmlwidgets", "lib", package = "findInGit")
#' tmpDir <- paste0(tempdir(), "_gitrepo")
#' dir.create(tmpDir)
#' # set tmpDir as the working directory
#' cd <- setwd(tmpDir)
#' # copy folder1 in tmpDir
#' copyDirectory(folder1, recursive = FALSE)
#' # initialize git repo
#' system("git init")
#' # add all files to git
#' system("git add -A")
#' # commit files
#' system('git commit -m "mycommit1"')
#' # create a new branch
#' system("git checkout -b newbranch")
#' # copy folder2 in tmpDir, under the new branch
#' copyDirectory(folder2, recursive = FALSE)
#' # add all files to git
#' system("git add -A")
#' # commit files
#' system('git commit -m "mycommit2"')
#'
#' # now we can try `findInGit`
#' \donttest{findInGit(ext = "js", pattern = "ansi")}
#'
#' # get results in a dataframe:
#' \donttest{findInGit(ext = "js", pattern = "ansi", output = "dataframe")}
#'
#' # one can also get the widget and the dataframe:
#' fig <- findInGit(ext = "css", pattern = "color", output = "viewer+dataframe")
#' fig
#' FIG2dataframe(fig)
#'
#' # return to initial current directory
#' setwd(cd)
#' # delete tmpDir
#' unlink(tmpDir, recursive = TRUE, force = TRUE)
findInGit <- function(
  ext, pattern,
  wholeWord = FALSE, ignoreCase = FALSE, perl = FALSE,
  excludePattern = NULL, excludeFoldersPattern = NULL,
  root = ".", output = "viewer"
){

  if(inSolaris() && Sys.which("ggrep") == ""){
    message("On Solaris, this package requires the 'ggrep' system command.")
    return(invisible(NULL))
  }

  if(!inSolaris() && Sys.which("grep") == ""){
    message("This package requires the 'grep' system command.")
    return(invisible(NULL))
  }

  if(Sys.which("git") == ""){
    message("This package requires the 'git' system command.")
    return(invisible(NULL))
  }

  stopifnot(isString(ext))
  if(isBinaryExtension(ext)){
    stop(
      sprintf("Invalid file extension '%s' (binary file).", ext),
      call. = TRUE
    )
  }

  output <- match.arg(output, c("viewer", "dataframe", "viewer+dataframe"))

  results <- grepInGit(
    ext = ext, pattern = pattern,
    wholeWord = wholeWord, ignoreCase = ignoreCase, perl = perl,
    excludePattern = excludePattern,
    excludeFoldersPattern = excludeFoldersPattern,
    directory = root, output = output
  )

  if(output %in% c("dataframe", "viewer+dataframe")){
    if(output == "viewer+dataframe"){
      strippedResults <- strip_style(results)
    }else{
      strippedResults <- results
    }
    strippedResults <- str_remove(strippedResults, "^BRANCH~~")
    strippedResults <- str_replace(strippedResults, "~~", ":.")
    resultsMatrix <- str_split_fixed(strippedResults, ":", n = 4L)
    colnames(resultsMatrix) <- c("branch", "file", "line", "code")
    resultsDF <- as.data.frame(resultsMatrix, stringsAsFactors = FALSE)
    resultsDF[["line"]] <- as.integer(resultsDF[["line"]])
    class(resultsDF) <- c(oldClass(resultsDF), "findInGit")
    if(output == "dataframe"){
      return(resultsDF)
    }
  }

  if(is.null(results)){
    ansi <- "No results."
  }else{
    ansi <- paste0(results, collapse = "\n")
  }

  # forward options using x
  if(output == "viewer"){
    x = list(
      ansi = ansi
    )
  }else{ # viewer+dataframe
    x = list(
      ansi = ansi,
      results = resultsDF
    )
  }

  # create widget
  htmlwidgets::createWidget(
    name = "findInGit",
    x = x,
    width = NULL,
    height = NULL,
    package = "findInGit",
    elementId = NULL
  )

}

#' Output of `findInGit` as a dataframe
#'
#' Returns the results of \code{\link{findInGit}} in a dataframe, when the
#'   option \code{output = "viewer+dataframe"} is used. See the example in
#'   \code{\link{findInGit}}.
#'
#' @param fig the output of \code{\link{findInGit}} used with the
#'   option \code{output = "viewer+dataframe"}
#'
#' @return The results of \code{\link{findInGit}} in a dataframe.
#' @export
FIG2dataframe <- function(fig){
  if(is.data.frame(fig) && inherits(fig, "findInGit")){
    return(fig)
  }
  if(!inherits(fig, c("findInGit", "htmlwidget"))){
    stop(
      "The `fig` argument is not a output of `findInGit`.",
      call. = TRUE
    )
  }
  output <- fig[["x"]][["results"]]
  if(is.null(output)){
    message(
      'You did not set the option `output = "viewer+dataframe"`.'
    )
    return(invisible(NULL))
  }
  output
}


#' Shiny bindings for \code{findInGit}
#'
#' Output and render functions for using \code{findInGit} within Shiny
#' applications and interactive Rmd documents.
#'
#' @param outputId output variable to read from
#' @param width,height a valid CSS unit (like \code{"100\%"},
#'   \code{"400px"}, \code{"auto"}) or a number, which will be coerced to a
#'   string and have \code{"px"} appended
#' @param expr an expression that generates a '\code{\link{findInGit}}' widget
#' @param env the environment in which to evaluate \code{expr}
#' @param quoted logical, whether \code{expr} is a quoted expression (with
#'   \code{quote()})
#'
#' @return \code{FIGOutput} returns an output element that can be included in a
#'   Shiny UI definition, and \code{renderFIG} returns a
#'   \code{shiny.render.function} object that can be included in a Shiny
#'   server definition.
#'
#' @name findInGit-shiny
#'
#' @export
#'
#' @examples library(findInGit)
#' library(shiny)
#'
#' # First, we create a temporary git repo
#' library(R.utils) # to use the `copyDirectory` function
#' folder1 <- system.file("htmlwidgets", package = "findInGit")
#' folder2 <- system.file("htmlwidgets", "lib", package = "findInGit")
#' tmpDir <- paste0(tempdir(), "_gitrepo")
#' dir.create(tmpDir)
#' # set tmpDir as the working directory
#' cd <- setwd(tmpDir)
#' # copy folder1 in tmpDir
#' copyDirectory(folder1, recursive = FALSE)
#' # initialize git repo
#' system("git init")
#' # add all files to git
#' system("git add -A")
#' # commit files
#' system('git commit -m "mycommit1"')
#' # create a new branch
#' system("git checkout -b newbranch")
#' # copy folder2 in tmpDir, under the new branch
#' copyDirectory(folder2, recursive = FALSE)
#' # add all files to git
#' system("git add -A")
#' # commit files
#' system('git commit -m "mycommit2"')
#'
#' # Now let's play with Shiny
#' onKeyDown <- HTML(
#'   'function onKeyDown(event) {',
#'   '  var key = event.which || event.keyCode;',
#'   '  if(key === 13) {',
#'   '    Shiny.setInputValue(',
#'   '      "pattern", event.target.value, {priority: "event"}',
#'   '    );',
#'   '  }',
#'   '}'
#' )
#'
#' ui <- fluidPage(
#'   tags$head(tags$script(onKeyDown)),
#'   br(),
#'   sidebarLayout(
#'     sidebarPanel(
#'       selectInput(
#'         "ext", "Extension",
#'         choices = c("js", "css")
#'       ),
#'       tags$div(
#'         class = "form-group shiny-input-container",
#'         tags$label(
#'           class = "control-label",
#'           "Pattern"
#'         ),
#'         tags$input(
#'           type = "text",
#'           class = "form-control",
#'           onkeydown = "onKeyDown(event);",
#'           placeholder = "Press Enter when ready"
#'         )
#'       ),
#'       checkboxInput(
#'         "wholeWord", "Whole word"
#'       ),
#'       checkboxInput(
#'         "ignoreCase", "Ignore case"
#'       )
#'     ),
#'     mainPanel(
#'       FIGOutput("results")
#'     )
#'   )
#' )
#'
#' Clean <- function(){
#'   setwd(cd)
#'   unlink(tmpDir, recursive = TRUE, force = TRUE)
#' }
#'
#' server <- function(input, output){
#'
#'   onSessionEnded(Clean)
#'
#'   output[["results"]] <- renderFIG({
#'     req(input[["pattern"]])
#'     findInGit(
#'       ext = isolate(input[["ext"]]),
#'       pattern = input[["pattern"]],
#'       wholeWord = isolate(input[["wholeWord"]]),
#'       ignoreCase = isolate(input[["ignoreCase"]])
#'     )
#'   })
#'
#' }
#'
#' if(interactive()){
#'   shinyApp(ui, server)
#' }else{
#'   Clean()
#' }
FIGOutput <- function(outputId, width = "100%", height = "400px"){
  htmlwidgets::shinyWidgetOutput(
    outputId, "findInGit", width, height, package = "findInGit"
  )
}

#' @rdname findInGit-shiny
#' @export
renderFIG <- function(expr, env = parent.frame(), quoted = FALSE){
  if(!quoted){ expr <- substitute(expr) } # force quoted
  htmlwidgets::shinyRenderWidget(expr, FIGOutput, env, quoted = TRUE)
}
