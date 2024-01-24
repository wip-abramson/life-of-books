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
    repo_name = function(){
      netid = wrangler:name()
      netid+"/library"
    }
    home_page = function() {
      app:query_url(meta:rid,"library.html")
    }
    minter_page = function(eci) {
      app:query_url(meta:rid, "minter.html?eci="+eci)
    }


    library = function(_headers){
      app:html_page("manage Books", "",
      <<
      <h1>Living Library</h1>
      <h2>Manage Books</h2>
      <form action='#{app:event_url(meta:rid,"new_book")}'>
      <button type="submit">Add Book</button>
      </form>
      <h2>Books</h2>
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


    // Test the eci is a valid PICO?
    minter = function(eci, _headers) {

      eci != null => 
      app:html_page("mint book", "",
      <<
      #{wrangler:picoQuery(eci, book_repo_rid, "mint_page", {})}
      >>, _headers
      )
      |
      app:html_page("mint book", "",
      <<
      <h1>Error, No book to mint</h1>
      
      <button>Return to Library</button>
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
    pre {
      // minter_page = minter_page()
    }
    // send_directive("_redirect",{"url":minter_page})
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
      // ent:eci_to_mint:= child_eci
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
    

    fired {
      // TODO:handle garbage collection
      // ent:eci_to_mint := null
      // raise com_futurewip_library event "navigate_home"
    }
  }
	

  rule bookMinted {
    select when com_futurewip_library book_minted
    pre {
      book_eci = event:attr("eci")
      // book_eci = ent:eci_to_mint.klog("Minted ECI")
      home_page = home_page()
    }
    if book_eci then noop()
    fired {

      ent:bookEcis := ent:bookEcis.append(ent:eci_to_mint)
      ent:eci_to_mint := null
      // raise com_futurewip_library event "navigate_home"
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
