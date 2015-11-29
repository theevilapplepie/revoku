Function server_getServerInfo(servername as String) as Dynamic

  ' Convert ServerName to Server URL
  serverURL = registry_sectionRead("servers",servername)

  ' Get JSON Data from Server
  response = api_getServerInfo(serverURL)

  ' Check to see if we have our expected data
  errorresponse = invalid
  if Type(response) = "roAssociativeArray" then
    if response.servername = invalid then
      errorresponse = "JSON Result is missing Server Name, API Version Mismatch?"
    else if response.version = invalid then
      errorresponse = "JSON Result is missing Version, API Version Mismatch?"
    else if response.shares = invalid then
      errorresponse = "JSON Result is missing Shares, API Version Mismatch?"
    end if
  else if response = false then
    ' We received no data or couldn't connect
    errorresponse = "No response received!"
  else if response = invalid
    ' We received invalid JSON
    errorresponse = "Invalid JSON Returned"
  endif

  ' If we have an error, Return the error
  if errorresponse <> invalid then
    return { error : errorresponse }
  end if

  ' No Errors, Return Success
  return response

End Function

Sub server_addServer()

  restart:
  while true

    serverURL = interface_keyboardEntry("Add Server","","Enter the full URL to a Revoku Server")

    ' Validate input
    if serverURL = invalid then
      return
    endif
    if serverURL = "" then
      interface_notifyDialog("No Input", "A Server URL was not supplied!")
      goto restart
    endif

    ' Put up Modal Dialog during attempt
    processingmodal = CreateObject("roOneLineDialog")
    processingmodal.SetTitle("Connecting, Please wait.")
    processingmodal.Show()
    processingmodal.ShowBusyAnimation()

    ' Clean URL
    r = CreateObject("roRegex", "^http[s]:\/\/", "i")
    if r.isMatch(serverURL) = false then
      serverURL = "http://" + serverURL
    endif

    ' Get JSON Data from Server
    response = api_getServerInfo(serverURL)

    ' Check to see if we have our expected data
    if Type(response) = "roAssociativeArray" then
      if response.servername = invalid then
        errorresponse = "JSON Result is missing Server Name, API Version Mismatch?"
      else if response.version = invalid then
        errorresponse = "JSON Result is missing Version, API Version Mismatch?"
      else if response.shares = invalid then
        errorresponse = "JSON Result is missing Shares, API Version Mismatch?"
      else
        exit while
      end if
    else if response = false then
      ' We received no data or couldn't connect
      errorresponse = "No response received!"
    else if response = invalid
      ' We received invalid JSON
      errorresponse = "Invalid JSON Returned"
    endif

    ' Stop processing modal
    processingmodal.Close()

    ' Present Error Dialog
    interface_notifyDialog("Connection Failure!", "The server could not be found or produced an error response." + chr(10) + "Error Response: " + errorresponse + chr(10) + chr(10) + "Check Server Logs for additional information.")

  end while

  ' We have a valid JSON object to deal with!
  ' Confirm if we're good to move forward on this server
  shares = ""
  for each share in response.shares
    if shares <> ""
      shares = shares + ", "
    end if
    shares = shares + share
  end for
  message = "Would you like to add this server?" + chr(10) + chr(10) + "Hostname: " + response.servername + chr(10) + "Revoku Version: " + response.version + chr(10) + "Shares: " + shares
  if interface_confirmDialog("Confirm Server Add",message) = false then
    goto restart
  endif

  ' We are good to add!
  registry_sectionWrite("servers",response.servername,serverURL)
  ' The server has been added to the registry perminantly

  ' If it's the ONLY server, mark it as default
  servers = registry_sectionList("servers")
  if servers.Count() = 1 then
    registry_sectionWrite("config","default_server",response.servername)
  end if

  ' Save Registry changes
  registry_Flush()

End Sub

Function server_getDefaultServer() as String
  return registry_sectionRead("config","default_server")
End Function

Sub server_setDefaultServer(servername as String)
  registry_sectionWrite("config","default_server",servername)
End Sub

Function server_setCurrentServer(servername as String) as Boolean
  serverurl = registry_sectionRead("servers",servername)
  if serverurl <> invalid AND serverurl <> "" then
    m.serverURL = serverurl
    m.server = servername
    return true
  end if
  return false
End Function

Function server_getCurrentServer() as String
  return m.server
End Function

Sub server_selectServer()
  ' Put up Modal Dialog during attempt
  processingmodal = CreateObject("roOneLineDialog")
  processingmodal.SetTitle("Validating Servers, Please Wait.")
  processingmodal.Show()
  processingmodal.ShowBusyAnimation()

  ' Connect and generate list
  menulist = []
  for each server in registry_sectionList("servers")
    serverreturn = {
      "Title" : server
      "ShortDescriptionLine1" : server
      "ShortDescriptionLine2" : registry_sectionRead("servers",server)
      "HDPosterUrl" : "pkg:/images/network.png"
    }
    result = server_getServerInfo(server)
    if result.error <> invalid then
      serverreturn.Title = serverreturn.Title + " (Offline)"
      serverreturn.ShortDescriptionLine1 = serverreturn.ShortDescriptionLine1 + " (Offline)"
      serverreturn.ShortDescriptionLine2 = result.error
    else
      shares = ""
      for each share in result.shares
        if shares <> "" then
          shares = shares + ", "
        end if
        shares = shares + share
      end for
      serverreturn.ShortDescriptionLine2 = "URL: " + registry_sectionRead("servers",server) + chr(10) + "Shares: " + shares
    end if
    menulist.push(serverreturn)
  end for

  ' Close Modal
  processingmodal.close()

  ' Event Loop
  while true

    ' Show screen and get response
    result = interface_listScreen("Welcome, " + m.userGN, m.server, "Switch Server", "Switch Server", menulist, 0)

    if result.action = invalid OR result.action = "" then
      return
    end if

    if result.action = "selected" OR result.action = "right" then
      server_setCurrentServer = result.object.Title
      interface_notifyDialog("Server Select", "Server " + result.object.Title + " has been selected!")
      return
    end if

    if result.action = "back" OR result.action = "left" then
      return
    end if

  end while

End Sub

Sub server_mainMenu()
   menulist = [
    {
      "Title" : "Add a Server"
      "ShortDescriptionLine1" : "Add a Server"
      "ShortDescriptionLine2" : "Add a new Revoku Server to Connect to"
      "HDPosterUrl" : "pkg:/images/foldernetwork.png"
    }
    {
      "Title" : "Delete a Server"
      "ShortDescriptionLine1" : "Delete a Server"
      "ShortDescriptionLine2" : "Remove a Revoku Server from this Client"
      "HDPosterUrl" : "pkg:/images/gears.png"
    }
  ]
  while true
    result = interface_listScreen("Welcome, " + m.userGN, m.server, "Manage Servers", "Manage Servers", menulist, 0)

    if type(result) <> "roAssociativeArray" OR result.Title = "" then
      return
    end if

    if result.action = "back" OR result.action = "left" then
      return
    end if

    ' Begin our cases for calls
    if ( result.action = "right" OR result.action = "selected" ) AND result.object.Title = "Add a Server" then
      server_addServer()
    end if
    if ( result.action = "right" OR result.action = "selected" ) AND result.object.Title = "Delete a Server" then
      server_deleteServer()
    end if

  End while
End Sub

Sub server_deleteServer()
  ' Put up Modal Dialog during attempt
  processingmodal = CreateObject("roOneLineDialog")
  processingmodal.SetTitle("Validating Servers, Please Wait.")
  processingmodal.Show()
  processingmodal.ShowBusyAnimation()

  ' Connect and generate list
  menulist = []
  for each server in registry_sectionList("servers")
    serverreturn = {
      "Title" : server
      "ShortDescriptionLine1" : server
      "ShortDescriptionLine2" : registry_sectionRead("servers",server)
      "HDPosterUrl" : "pkg:/images/network.png"
    }
    result = server_getServerInfo(server)
    if result.error <> invalid then
      serverreturn.Title = serverreturn.Title + " (Offline)"
      serverreturn.ShortDescriptionLine1 = serverreturn.ShortDescriptionLine1 + " (Offline)"
      serverreturn.ShortDescriptionLine2 = result.error
    else
      shares = ""
      for each share in result.shares
        if shares <> "" then
          shares = shares + ", "
        end if
        shares = shares + share
      end for
      serverreturn.ShortDescriptionLine2 = "URL: " + registry_sectionRead("servers",server) + chr(10) + "Shares: " + shares
    end if
    menulist.push(serverreturn)
  end for

  ' Close Modal
  processingmodal.close()

  ' Event Loop
  while true

    ' Show screen and get response
    result = interface_listScreen("Welcome, " + m.userGN, m.server, "Delete Server", "Delete Server", menulist, 0)

    if result.action = invalid OR result.action = "" then
      return
    end if

    if result.action = "selected" then
      confirm = interface_confirmDialog("Confirm Delete", "Are you sure you want to delete " + result.object.Title + "?")
      if confirm then
        if server_getCurrentServer() <> result.object.Title then
          registry_sectionDelete("servers", result.object.Title)
          interface_notifyDialog("Server Deleted", "The Server " + result.object.Title + " has been removed.")
        else
          interface_notifyDialog("Error Deleting", "The Server " + result.object.Title + " is currently in use by Revoku, Switch to a different server before removing.")
          return
        end if
      end if
      return
    end if

    if result.action = "back" OR result.action = "left" then
      return
    end if

  end while

End Sub

Sub server_browseShares()

  ' Put up Modal Dialog during attempt
  processingmodal = CreateObject("roOneLineDialog")
  processingmodal.SetTitle("Getting Server Information, Please Wait.")
  processingmodal.Show()
  processingmodal.ShowBusyAnimation()

  ' Connect and generate list
  menulist = []
  result = server_getServerInfo(server_getCurrentServer())
  if result.error <> invalid then
    interface_notifyDialog("Server Unavailable", "The Server did not respond to the information request." + chr(10) + "Error: " + result.error)
    return
  end if
  for each share in result.shares
    menulist.push({
      "Title" : share
      "ShortDescriptionLine1" : share
      "ShortDescriptionLine2" : share + " on " + server_getCurrentServer()
      "HDPosterUrl" : "pkg:/images/foldernetwork.png"
      "Url" : share
    })
  end for

  ' Close Modal
  processingmodal.close()

  ' Event Loop
  while true

    ' Show screen and get response
    result = interface_listScreen("Welcome, " + m.userGN, m.server, "Browse Shares", "Browse Shares", menulist, 0)

    if result.action = invalid OR result.action = "" then
      return
    end if

    if result.action = "selected" OR result.action = "right" then
      server_browsePath([result.object.Url])
    end if

    if result.action = "back" OR result.action = "left" then
      return
    end if

  end while

End Sub

Sub server_browsePath(stack as Dynamic)

  ' Create object for urlencode
  urlobj = CreateObject("roUrlTransfer")

  ' Event Loop
  while true

    ' Show Modal
    processingmodal = CreateObject("roOneLineDialog")
    processingmodal.SetTitle("Requesting, Please Wait.")
    processingmodal.Show()
    processingmodal.ShowBusyAnimation()

    ' Connect and generate list
    menulist = []
    ' Create Path
    path = ""
    for each pathcomponent in stack
      if path <> "" then
        path = path + "/"
      end if
      path = path + pathcomponent
    end for
    result = shared_getURLJSON(m.serverURL + "?action=pathlist&path=" + urlobj.Escape(path))

    if result = invalid then
      interface_notifyDialog("Server Error", "The Server did not respond to the information request.")
      return
    end if

    ' Parse what we got back from the server :|
    for i = 0 to ( result.Count() - 1 )
      ' Set Image if one isn't set :)
      if result[i].HDPosterUrl = invalid AND result[i].type = "directory"
        result[i].HDPosterUrl = "pkg:/images/folder.png"
      else if result[i].HDPosterUrl = invalid AND result[i].type = "video"
        result[i].HDPosterUrl = "pkg:/images/video.png"
      else if result[i].HDPosterUrl = invalid AND result[i].type = "audio"
        result[i].HDPosterUrl = "pkg:/images/audio.png"
      else if result[i].HDPosterUrl = invalid
        result[i].HDPosterUrl = "pkg:/images/file.png"
      end if
      ' Set up Title for Content if there is none
      if result[i].ShortDescriptionLine1 = invalid AND result[i].type = "directory"
        result[i].ShortDescriptionLine1 = "Directory"
      else if result[i].ShortDescriptionLine1 = invalid AND result[i].type = "video"
        result[i].ShortDescriptionLine1 = "Video File"
      else if result[i].ShortDescriptionLine1 = invalid AND result[i].type = "audio"
        result[i].ShortDescriptionLine1 = "Audio File"
      else if result[i].ShortDescriptionLine1 = invalid
        result[i].ShortDescriptionLine1 = "Unknown File"
      end if
      if result[i].ShortDescriptionLine2 = invalid
        result[i].ShortDescriptionLine2 = "No Metadata Available"
      end if
    end for

    ' Create a "pretty path"
    visiblepath = ""
    if stack.Count() > 1 then
      for i=1 to ( stack.Count() - 1 )
        if visiblepath <> "" then
          visiblepath = visiblepath + "/"
        end if
        visiblepath = visiblepath + stack[i]
      end for
    else
      visiblepath = stack[0]
    end if

    ' Close Modal
    processingmodal.close()

    ' Show screen and get response
    result = interface_listScreen("Welcome, " + m.userGN, m.server, stack[0], visiblepath, result, 0)

    if result.action = invalid OR result.action = "" then
      return
    else if result.action = "selected" OR result.action = "right" then
      if result.object.type = "directory" then
        stack.Push(result.object.url)
      else if result.object.type = "audio" then
      else if result.object.type = "video" then
        action = interface_displayVideoInfo(m.server, stack[0], path + "/" + result.object.Url)
        if action = "play" then
          interface_displayVideo(result.object.Title, path + "/" + result.object.Url)
        end if
      else
        interface_notifyDialog("Unknown FileType", "This type of file cannot be played.")
      end if
    else if result.action = "back" OR result.action = "left" then
      if ( stack.Count() = 1 ) then
        return
      end if
      stack.Pop()
    end if

  end while

End Sub