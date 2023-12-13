ruleset com.futurewip.book {
  meta {
    name "Books"
    use module io.picolabs.wrangler alias wrangler
    shares book
  }
  global {


    book = function() {
      <<<h2>#{ent:title}</h2> 
      >>
    }
  }


  rule pico_created {
    select when wrangler:pico_created

    pre {
      title = event:attrs.get("title")
    }
    fired {
      ent:title:= title
    }
  }

	rule ruleset_installed {
    select when wrangler:ruleset_installed

  }


}
