#* Github commit SHA
#* 
#* Each release of the API is based on some Github commit. This endpoint allows
#* the user to easily check the SHA of the deployed API version.
#* 
#* @get /sha
#* @serializer unboxedJSON
function() {
  Sys.getenv("GITHUB_SHA", unset = "")
}
