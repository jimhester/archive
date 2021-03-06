#' Create a writable connection to a file in an archive.
#'
#' @param archive `character(1)` The archive filename or an `archive` object.
#' @param file `character(1) || integer(1)` The filename within the archive,
#'   specified either by filename or by position.
#' @param mode `character(1)` A description of how to open the
#'   connection (if it should be opened initially).  See section
#'   ‘Modes’ in [base::connections()] for possible values.
#' @template archive
#' @importFrom rlang is_character is_named
#' @details
#' For traditional zip archives [archive_write()] creates a connection which
#' writes the data to the specified file directly. For other archive formats
#' the file size must be known when the archive is created, so the data is
#' first written to a scratch file on disk and then added to the archive. This
#' scratch file is automatically removed when writing is complete.
#' @returns An 'archive_write' connection to the file within the archive to be written.
#' @examples
#' # Archive format and filters can be set automatically from the file extensions.
#' f1 <- tempfile(fileext = ".tar.gz")
#'
#' write.csv(mtcars, archive_write(f1, "mtcars.csv"))
#' archive(f1)
#' unlink(f1)
#'
#' # They can also be specified explicitly
#' f2 <- tempfile()
#' write.csv(mtcars, archive_write(f2, "mtcars.csv", format = "tar", filter = "bzip2"))
#' archive(f2)
#' unlink(f2)
#'
#' # You can also pass additional options to control things like compression level
#' f3 <- tempfile(fileext = ".tar.gz")
#' write.csv(mtcars, archive_write(f3, "mtcars.csv", options = "compression-level=2"))
#' archive(f3)
#' unlink(f3)
#' @export
archive_write <- function(archive, file, mode = "w", format = NULL, filter = NULL, options = character()) {
  if (is.null(format) && is.null(filter)) {
    res <- format_and_filter_by_extension(archive)

    assert("Could not automatically determine the `filter` and `format` from `archive` {archive}",
      !is.null(res))

    format <- res[[1]]
    filter <- res[[2]]
  }

  assert("`archive` {archive} must be a writable file path",
    is_writable(dirname(archive)))

  archive <- normalizePath(archive, mustWork = FALSE)

  assert("`file` must be a length one character vector",
    is_string(file))

  options <- validate_options(options)

  if (identical(format, "zip") || identical(format, "raw")) {
    return(archive_write_direct_(archive, file, mode, archive_formats()[format], archive_filters()[filter], options, 2^14))
  }

  archive_write_(archive, file, mode, archive_formats()[format], archive_filters()[filter], options, 2^14)
}
