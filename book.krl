ruleset com.futurewip.book {
  meta {
    name "Books"
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.plan.apps alias app
    shares book
  }
  global {


    book = function() {

    }
  }



	rule ruleset_installed {
    select when wrangler:ruleset_installed

  }


}
