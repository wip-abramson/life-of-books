ruleset com.futurewip.library {
  meta {
    name "Living Library"
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.plan.apps alias app
    shares library
  }
  global {
    repo_rid = "com.futurewip.library"
    book_repo_rid = "com.futurewip.book"
    repo_name = function(title){
      netid = wrangler:name()
      netid+"/library/"+title
    }
    library = function(_headers){
      app:html_page("manage Books", "",
<<
<h1>Living Library</h1>
<h2>Manage Books</h2>
<form action="#{app:event_url(meta:rid,"book_added")}">
<label>Book Title</label>
<input name="title" autofocus/>
<button type="submit">Mint Book</button>
</form>
<ul>
#{ent:bookEcis.map(function(bookEci) {
<<
<li>#{wrangler:picoQuery(bookEci, book_repo_rid, "book", {})}</li>
>>
}).join("")
}
</ul>
>>, _headers)
    }

  }

  rule initialize {
    select when com_futurewip_library factory_reset
    where ent:bookEcis.isnull()
    fired {
      ent:bookEcis:= []
    }
  }
  
  rule addBook {
    select when com_futurewip_library book_added
    title re#(.+)#
    setting(title)

    fired {
      raise wrangler event "new_child_request" attributes
        event:attrs.put("name",repo_name(title)).put("title", title)
    }
  }

  rule handleChildDeletion {
    select when wrangler:child_deletion_request

    pre {
      bookToDelete = event:attr("eci)
      bookIndex = ent:bookEcis.index(bookToDelete)
    }
    if bookIndex >= 0 then noop()

    fired {
      ent:bookEcis = ent:bookEcis.splice(bookIndex, 1)

    }
  }
	
  rule reactToChildCreation {
    select when wrangler:new_child_created
    pre {
      child_eci = event:attrs("eci")
      title = event:attrs("title")
    }
    if child_eci then

      event:send({"eci":child_eci,
        "domain":"wrangler","type":"install_ruleset_request",
        "attrs":{"absoluteURL": "https://raw.githubusercontent.com/wip-abramson/life-of-books/main/com.futurewip.book.krl","rid":book_repo_rid, "title": title}
      })
    fired {
      ent:bookEcis:= ent:bookEcis.append(child_eci)
      raise ruleset event "repo_installed" // terminal event
    }
  }

  rule redirectBack {
     select when com_futurewip_library book_added
     pre {
       home_page = app:query_url(meta:rid,"library.html")
     }
     send_directive("_redirect",{"url":home_page})
  }
}
