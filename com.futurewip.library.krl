ruleset com.futurewip.library {
  meta {
    name "Living Library"
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.plan.apps alias app
    shares library, home_page, minter, book_page, book
  }
  global {
    event_domain = "com_futurewip_library"
    repo_rid = "com.futurewip.library"
    stylesheet = "<link rel='stylesheet' href='https://cdn.jsdelivr.net/npm/bulma@0.9.4/css/bulma.min.css'>"
    book_repo_rid = "com.futurewip.book"
    repo_name = function(){
      netid = wrangler:name()
      netid+"/book"
    }
    home_page = function() {
      app:query_url(meta:rid,"library.html")
    }
    minter_page = function(eci) {
      app:query_url(meta:rid, "minter.html?eci="+eci)
    }

    book_page = function(book_eci) {
      app:query_url(meta:rid, "book.html?eci="+book_eci)
    }


    library = function(_headers){
      app:html_page("manage Books", stylesheet,
      <<
      <h1>Living Library</h1>
      <h2>Manage Books</h2>
      <form action='#{app:event_url(meta:rid,"new_book")}'>
      <button type="submit">Add Book</button>
      </form>
      <h2>Books</h2>
      
      #{ent:bookEcis.map(function(bookEci) {
      <<
      #{wrangler:picoQuery(bookEci, book_repo_rid, "list_view", {})}
      >>
      }).join("")
      }
      
      >>, _headers)
    }

    book = function(eci, _headers) {
      eci!=null && ent:bookEcis.index(eci) != -1 => 
      app:html_page("book details", stylesheet,
      <<
      #{wrangler:picoQuery(eci, book_repo_rid, "book_view", {})}
      >>, _headers
      )
      |
      app:html_page("error page", "",
      <<
      <h1>Error, No book found</h1>
      <form action='#{app:event_url(meta:rid,"navigate_home")}'>
      <button type="submit">Return to Library</button>
      </form>
      >>, _headers
      )
    }


    // Test the eci is a valid PICO?
    minter = function(eci, _headers) {

      eci != null && ent:minting_ecis.index(eci) != -1 => 
      app:html_page("mint book", stylesheet,
      <<
      #{wrangler:picoQuery(eci, book_repo_rid, "mint_page", {})}
      >>, _headers
      )
      |
      app:html_page("error page", "",
      <<
      <h1>Error, No book to mint</h1>
      <form action='#{app:event_url(meta:rid,"navigate_home")}'>
      <button type="submit">Return to Library</button>
      </form>
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
  
  rule newBook {
    select when com_futurewip_library new_book

    fired {
      raise wrangler event "new_child_request" attributes
        event:attrs.put("name",repo_name())
    }
  } 


  rule reactToChildCreation {
    select when wrangler:new_child_created
    pre {
      child_eci = event:attr("eci")
      html_page = minter_page(child_eci)
    }
    if child_eci then every {
      event:send({"eci":child_eci,
        "domain":"wrangler","type":"install_ruleset_request",
        "attrs":{"absoluteURL": "https://raw.githubusercontent.com/wip-abramson/life-of-books/main/com.futurewip.book.krl","rid":book_repo_rid,}
      })
      send_directive("_redirect",{"url":html_page})
    }

    fired {
      // Add to list of pending ecis or something
      ent:minting_ecis:= ent:minting_ecis.append(child_eci)
      raise ruleset event "repo_installed" // terminal event
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

  rule handleMintCancelled {
    select when com_futurewip_library cancel_mint
    pre {
      child_eci = event:attr("eci")
      mint_eci_index = ent:minting_ecis.index(child_eci)
    }
    if child_eci then noop()

    fired {
      ent:minting_ecis := ent:minting_ecis.splice(mint_eci_index, 1)
    }
  }
	

  rule bookMinted {
    select when com_futurewip_library book_minted
    pre {
      book_eci = event:attr("eci")
      mint_eci_index = ent:minting_ecis.index(book_eci)
      home_page = home_page()
    }
    if book_eci then noop()
    fired {

      ent:bookEcis := ent:bookEcis.append(book_eci)
      // Tidy up pending list
      ent:minting_ecis := ent:minting_ecis.splice(mint_eci_index, 1)

    }
  }

  rule redirectHome {
     select when com_futurewip_library book_deleted or
      com_futurewip_library navigate_home
     pre {
       home_page = home_page()
     }
     send_directive("_redirect",{"url":home_page})
  }
}
