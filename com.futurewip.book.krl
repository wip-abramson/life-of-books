ruleset com.futurewip.book {
  meta {
    name "Books"
    use module io.picolabs.wrangler alias wrangler
    shares book
  }
  global {


    book = function() {
      <<
      <div>
      <h2>#{ent:title}</h2> 
      <button onclick="#{event_url(meta:rid,"book_added")}">Remove</button>
      </div>
      >>
    }

    event_url = function(event_type,event_id){
          eci = wrangler:channels(["library","book"]).reverse().head().get("id")
      eid = event_id || "none"
      event_domain = "com_futurewip_book"
      <<#{meta:host}/sky/event/#{eci}/#{eid}/#{event_domain}/#{event_type}>>
    }
    query_url = function(query_name){
      eci = wrangler:channels(["library","book"]).reverse().head().get("id")
      <<#{meta:host}/c/#{eci}/query/#{meta:rid}/#{query_name}>>
    }
  }

  rule remove_book {
    select when com_futurewip_book remove_book

    fired {
      raise wrangler event "ready_for_deletion"
    }
  }


	rule ruleset_installed {
    select when wrangler:ruleset_installed
    pre {
      title = event:attrs.get("title")
    }
    if !title then noop()
    fired {
      ent:title:= title
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        ["library","book"],
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
    foreach wrangler:channels(["library","book"]).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }




}
