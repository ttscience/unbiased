#* Return hello world
#* 
#* @get /hello
function() {
  call_hello_world()
}

call_hello_world <- function() {
  Sys.getenv("GITHUB_SHA", unset = "none")
}
