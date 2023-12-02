ruleset com.futurewip.book {
  meta {
    name "Books"
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.plan.apps alias app
    shares book
  }
  global {
    repo_rid = "com.futurewip.book"
    repo_name = function(title){
      netid = wrangler:name()
      netid+"/library/"+title
    }
  }

  rule initialize {
    select when com_futurewip_book factory_reset
    where ent:books.isnull()
    fired {
      ent:books:= [{"title": "1491"}]
    }
    
  }

	
  rule reactToChildCreation {
    select when wrangler:new_child_created
    pre {
      child_eci = event:attr("eci")
    }
    if child_eci then
      event:send({"eci":child_eci,
        "domain":"wrangler","type":"install_ruleset_request",
        "attrs":{"absoluteURL": meta:rulesetURI,"rid":repo_rid}
      })
    fired {
      raise ruleset event "repo_installed" // terminal event
    }
  }
  rule redirectBack {
     select when com_futurewip_book book_added
     pre {
       home_page = app:query_url(meta:rid,"book.html")
     }
     send_directive("_redirect",{"url":home_page})
  }
}
