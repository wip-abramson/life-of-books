ruleset com.futurewip.library {
  meta {
    name "Living Library"
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.plan.apps alias app
    shares library, home_page, minter
  }
  global {
    event_domain = "com_futurewip_library"
    repo_rid = "com.futurewip.library"
    book_repo_rid = "com.futurewip.book"
    repo_name = function(title){
      netid = wrangler:name()
      netid+"/library/"+title
    }
    home_page = function() {
      app:query_url(meta:rid,"library.html")
    }
    minter_page = function() {
      app:query_url(meta:rid, "minter.html")
    }


    library = function(_headers){
      app:html_page("manage Books", "",
      <<
      <h1>Living Library</h1>
      <h2>Manage Books</h2>
      <form action='#{app:event_url(meta:rid,"book_added")}'>
      <label>Book Title</label>Library
      <input name="title" autofocus/>
      <button type="submit">Add Book</button>
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

    minter = function(_headers) {
      app:html_page("mint book", "",
      <<
      <h1>Mint Book</h1>
      #{wrangler:picoQuery(ent:eci_to_mint, book_repo_rid, "mint_page", {})}
      >>, _headers
      )
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
    select when wrangler:child_deleted
    pre {
      bookToDelete = event:attr("eci")
      bookIndex = ent:bookEcis.index(bookToDelete)
    }
    if bookIndex >= 0 then noop()

    fired {
      ent:bookEcis := ent:bookEcis.splice(bookIndex, 1)
      // raise com_futurewip_library event "book_deleted"

    }
  }
	
  rule reactToChildCreation {
    select when wrangler:new_child_created
    pre {
      child_eci = event:attr("eci")
      title = event:attr("title")
      minter_page = minter_page()
    }
    if child_eci then 
      event:send({"eci":child_eci,
        "domain":"wrangler","type":"install_ruleset_request",
        "attrs":{"absoluteURL": "https://raw.githubusercontent.com/wip-abramson/life-of-books/main/com.futurewip.book.krl","rid":book_repo_rid, "title": title}
      })

    fired {
      ent:eci_to_mint:= child_eci
      raise com_futurewip_library event "book_deleted"
      raise ruleset event "repo_installed" // terminal event
    }
  }

  rule navigateToMinter {
    select when com_futurewip_library book_added

    pre {
      minter_page = minter_page()
    }
    send_directive("_redirect",{"url":minter_page})
  }

  rule redirectBack {
     select when com_futurewip_library book_deleted
     pre {
       home_page = home_page()
     }
     send_directive("_redirect",{"url":home_page})
  }
}
