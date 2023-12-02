ruleset com.futurewip.book {
  meta {
    name "Books"
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.plan.apps alias app
    shares book
  }
  global {
    repo_rid = "com.futurewip.books"
    repo_name = function(title){
      netid = wrangler:name()
      netid+"/library/"+title
    }
    book = function(_headers){
      app:html_page("manage Books", "",
<<
<h1>Manage Books</h1>
<form action="#{app:event_url(meta:rid,"book_added")}">
<label>Book Title</label>
<input name="title" autofocus/>
<button type="submit">Add Book</button>
</form>
<ul>
#{wrangler:children().map(function(child) {
<<
<li>#{child.get("name")}</li>
>>
}).join("")
}
</ul>
>>, _headers)
    }

  }

  rule initialize {
    select when com_futurewip_book factory_reset
    where ent:books.isnull()
    fired {
      ent:books:= [{"title": "1491"}]
    }
    
  }
  rule addBook {
    select when com_futurewip_book book_added
      title re#(.+)#
      setting(title)

    fired {
      ent:books:= ent:books.append({"title":title})
      raise wrangler event "new_child_request" attributes
        event:attrs.put("name",repo_name(title))
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
