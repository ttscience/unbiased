#* @plumber
function(api) {
  meta <- plumber::pr("meta.R")

  api |>
    plumber::pr_mount("/meta", meta)
}

#* Return hello world
#*
#* @get /simple/hello
#* @serializer unboxedJSON
function() {
  unbiased:::call_hello_world()
}
