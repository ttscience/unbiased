#* Return hello world
#* 
#* @get /hello
#* @serializer unboxedJSON
function() {
  call_hello_world()
}

call_hello_world <- function() {
  "Hello TTSI!"
}
