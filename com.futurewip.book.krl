ruleset com.futurewip.book {
  meta {
    name "Books"
    use module io.picolabs.wrangler alias wrangler
    shares book_view, mint_page, list_view
  }
  global {

    channel_tags = ["library","book"]
    event_domain = "com_futurewip_book"
    list_view = function() {
      <<<div>
      <h2>#{ent:title}</h2>
      <form method="POST" action='#{event_url("remove_book")}'>
      <button type="submit is-danger">Remove</button>
      </form>
      <form method="POST" action='#{event_url("open_book")}'>
      <button class="button is-primary"  type="submit">Open</button>
      </form>
      </div>
      >>   
    }
    book_view = function() {
      <<<div>
      <h1>Book Detail Page</h1>
      <h2>#{ent:title}</h2>
      <form method="POST" action='#{event_url("remove_book")}'>
      <button type="submit">Remove</button>
      </form>
      </div>
      >>   
    }

    mint_page = function() {
      <<<div>
      <h1>Mint Book</h2>
      <form method="POST" action='#{event_url("generate_from_isbn")}'>
      <div>
      <label>ISBN</label>
      <input type="text" autofocus/>
      </div>
      <button type="submit">Generate</button>
      </form>

      <form method="POST" action='#{event_url("mint_book")}'>
      <div>
      <label>Title</label>
      <input name="title" autofocus/>
      <label>Author</label>
      <input name="author" autofocus/>
      <button type="submit">Mint</button></div>
      </div>
      </form>
      <form method="POST" action='#{event_url("cancel_mint")}'>
      <button type="submit">Cancel</button></div>
      </form>
      </div>
      >>
    }

    event_url = function(event_type,event_id){
      eci = wrangler:channels(channel_tags).reverse().head().get("id")
      eid = event_id || "none"
      <<#{meta:host}/sky/event/#{eci}/#{eid}/#{event_domain}/#{event_type}>>
    }
    query_url = function(query_name){
      eci = wrangler:channels(["library","book"]).reverse().head().get("id")
      <<#{meta:host}/c/#{eci}/query/#{meta:rid}/#{query_name}>>
    }

    child_eci = function() {
      eci = wrangler:channels(["system", "child"]).head().get("id")
      eci
    }
  }

  rule cancel_mint {
    select when com_futurewip_book cancel_mint

    pre {
      my_eci = child_eci()
      parent_eci = wrangler:parent_eci() 
    }
    
    event:send({"eci":parent_eci,
    "domain":"com_futurewip_library","type":"cancel_mint", "attrs": {"eci": my_eci}  })

    fired {
      raise com_futurewip_book event "library_home"
      raise wrangler event "ready_for_deletion"
    }
  }

  rule remove_book {
    select when com_futurewip_book remove_book

    pre {
      referrer = event:attr("_headers").get("referer") // sic
    }
    if referrer then send_directive("_redirect",{"url":referrer})

    fired {
      raise wrangler event "ready_for_deletion"
    }
  }

  rule generate_from_isbn {
    select when com_futurewip_book generate_from_isbn
  }

  
  rule mint_book {
    select when com_futurewip_book mint_book
    title re#(.+)#
    author re#(.*)#
    setting(title, author)
    pre {
      parent_eci = wrangler:parent_eci()
      my_eci = child_eci()
    }
    if title then 
    event:send({"eci":parent_eci,
    "domain":"com_futurewip_library","type":"book_minted", "attrs": {"eci": my_eci} })


    fired {
      ent:title := title
      ent:author := author
      raise com_futurewip_book event "library_home"
    }

  }

  rule open_book {
    select when com_futurewip_book open_book
    pre {
      my_eci = child_eci()
      detail_url = wrangler:picoQuery(wrangler:parent_eci(),"com.futurewip.library", "book_page", {"book_eci": my_eci})
    }
    send_directive("_redirect", {"url": detail_url})
  }

  rule library_home {
    select when com_futurewip_book library_home
    pre {
      home_url = wrangler:picoQuery(wrangler:parent_eci(),"com.futurewip.library", "home_page", {})
    }
    send_directive("_redirect",{"url":home_url})
    
  }


	// rule ruleset_installed {
  //   select when wrangler:ruleset_installed
  //   pre {
  //     title = event:attr("title")
  //   }
  //   if title then noop()

  //   fired {
  //     ent:title:= title
  //   }
  // }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        channel_tags,
        {"allow":[{"domain":"com_futurewip_book","name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      ) setting(channel)
    }
    fired {
      raise com_futurewip_book event "channel_created"
    }
  }
  rule keepChannelsClean {
    select when com_futurewip_book channel_created
    foreach wrangler:channels(channel_tags).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }




}
