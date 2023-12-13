ruleset com.futurewip.book {
  meta {
    name "Books"
    use module io.picolabs.wrangler alias wrangler
    shares book
  }
  global {


    book = function() {
      "Test BOOK"
    }
  }



	rule ruleset_installed {
    select when wrangler:ruleset_installed

  }


}
