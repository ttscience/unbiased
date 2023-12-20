#* Github commit SHA
#*
#* Each release of the API is based on some Github commit. This endpoint allows
#* the user to easily check the SHA of the deployed API version.
#*
#* @get /sha
#* @serializer unboxedJSON
function(res) {
  sha <- Sys.getenv("GITHUB_SHA", unset = "NULL")
  if (sha == "NULL") {
    res$status <- 404
    return(c(error = "SHA not found"))
  } else {
    return(sha)
  }
}
