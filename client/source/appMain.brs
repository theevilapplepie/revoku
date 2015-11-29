Sub Main(args As Dynamic)

  ' Set theme
  interface_setApplicationTheme()

  ' Create a Facade to stop the app flashing back to home screen
  screenFacade = CreateObject("roParagraphScreen")
  screenFacade.show()

  ' Check if we have a previously selected server, Go ahead and set it up
  default_server = server_getDefaultServer()
  if default_server = invalid OR default_server = "" then
    server_selectServer()
  else
    server_setCurrentServer(default_server)
  end if

  ' Do we have ANY servers?
  while true
    servers = registry_sectionList("servers")
    if servers.Count() < 1 then
      server_addServer()
    end if
    servers = registry_sectionList("servers")
    if servers.Count() = 1 then
      server_setCurrentServer(servers[0])
    end if
    if servers.Count() > 0 then
      exit while
    end if
    interface_notifyDialog("No Servers", "No configured servers were found, Redirecting to Add Server.")
  end while

  ' Login a User
  m.user = "jvess"
  m.userGN = "James"
  m.userSN = "Vess"

  ' Go to Browse Shares if we haven't set to only go to the main menu
  if registry_sectionRead("preferences","default_to_mainmenu") = invalid OR registry_sectionRead("preferences","default_to_mainmenu") = "" then
    server_browseShares()
  end if

  ' Main Loop
  while true
    mainMenu()
  end while

  ' Exit the app gently so that the screen doesn't flash to black
  screenFacade.showMessage("")
  sleep(25)

End Sub

Sub mainMenu()
  menulist = [
    {
      "Title" : "Recently Played"
      "ShortDescriptionLine1" : "Recently Played"
      "ShortDescriptionLine2" : "Quickly Resume or Re-Watch"
      "HDPosterUrl" : "pkg:/images/video.png"
    }
    {
      "Title" : "Browse Shares"
      "ShortDescriptionLine1" : "Browse Shares"
      "ShortDescriptionLine2" : "Browse Media Shares on" + chr(10) + server_getCurrentServer()
      "HDPosterUrl" : "pkg:/images/foldernetwork.png"
    }
    {
      "Title" : "Preferences"
      "ShortDescriptionLine1" : "Preferences"
      "ShortDescriptionLine2" : "Configure Preferences for Revoku"
      "HDPosterUrl" : "pkg:/images/gears.png"
    }
    {
      "Title" : "Switch User"
      "ShortDescriptionLine1" : "Switch User"
      "ShortDescriptionLine2" : "Login as another user on this Server"
      "HDPosterUrl" : "pkg:/images/users.png"

    }
    {
      "Title" : "Switch Server"
      "ShortDescriptionLine1" : "Switch Server"
      "ShortDescriptionLine2" : "Select another Server to Browse"
      "HDPosterUrl" : "pkg:/images/network.png"
    }
    {
      "Title" : "Manage Users"
      "ShortDescriptionLine1" : "Manage Users"
      "ShortDescriptionLine2" : "Add/Modify/Remove Users on Server"
      "HDPosterUrl" : "pkg:/images/computer.png"

    }
    {
      "Title" : "Manage Servers"
      "ShortDescriptionLine1" : "Manage Servers"
      "ShortDescriptionLine2" : "Add/Remove Configured Revoku Servers"
      "HDPosterUrl" : "pkg:/images/macpro.png"
    }
    {
      "Title" : "Reset Revoku"
      "ShortDescriptionLine1" : "Reset Revoku"
      "ShortDescriptionLine2" : "Reset Revoku Client to Factory Defaults"
      "HDPosterUrl" : "pkg:/images/recycle.png"

    }
  ]
  result = interface_listScreen("Welcome, " + m.userGN, m.server, "Main Menu", "Main Menu", menulist, 0)
  if type(result) <> "roAssociativeArray" OR result.Title = "" then
    return
  end if

  ' Begin our cases for calls
  if ( result.action = "right" OR result.action = "selected" ) AND result.object.Title = "Switch Server" then
    server_selectServer()
  end if

  if ( result.action = "right" OR result.action = "selected" ) AND result.object.Title = "Manage Servers" then
    server_mainMenu()
  end if

  if ( result.action = "right" OR result.action = "selected" ) AND result.object.Title = "Browse Shares" then
    server_browseShares()
  end if


End Sub