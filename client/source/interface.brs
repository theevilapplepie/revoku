Sub interface_setApplicationTheme()
  app = CreateObject("roAppManager")
  theme = CreateObject("roAssociativeArray")
  theme.OverhangSliceHD = ""
  theme.OverhangSliceSD = ""
  theme.OverhangPrimaryLogoSD = "pkg:/logos/Logo_Overhang_ SD43.png"
  theme.OverhangPrimaryLogoOffsetSD_X = "0"
  theme.OverhangPrimaryLogoOffsetSD_Y = "0"
  theme.OverhangPrimaryLogoHD = "pkg:/logos/revoku_banner_HD.png"
  theme.OverhangPrimaryLogoOffsetHD_X = "0"
  theme.OverhangPrimaryLogoOffsetHD_Y = "0"
  theme.BackgroundColor = "#000000"
'  theme.ListScreenDescriptionText = "#FFFFFF"
'  theme.ListScreenTitleColor = "#FFFFFF"
  theme.ListItemText = "#c31818"
  theme.ListItemHighlightText = "#FFFFFF"
  theme.ListScreenHeaderText = "#FFFFFF"
  theme.ListItemHighlightText = "#FFFFFF"

  app.SetTheme(theme)
End Sub

Sub interface_notifyDialog(title as String, message as String)
    dialogport = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(dialogport)
    dialog.SetTitle(title)
    dialog.SetText(message)
    dialog.AddButton(1, "OK")
'    dialog.EnableBackButton(true)
    dialog.Show()
    while true
      dlgMsg = wait(0, dialog.GetMessagePort())
      if type(dlgMsg) = "roMessageDialogEvent" then
        if dlgMsg.isButtonPressed() then
          if dlgMsg.GetIndex() = 1 then
            return
          end if
        else if dlgMsg.isScreenClosed()
          return
        end if
      end if
    end while
End Sub

Function interface_confirmDialog(title as String, message as String) as Boolean
    dialogport = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(dialogport)
    dialog.SetTitle(title)
    dialog.SetText(message)
    dialog.AddButton(1, "Confirm")
    dialog.AddButton(2, "Cancel")
'    dialog.EnableBackButton(true)
    dialog.Show()
    while true
      dlgMsg = wait(0, dialog.GetMessagePort())
      if type(dlgMsg) = "roMessageDialogEvent" then
        if dlgMsg.isButtonPressed() then
          if dlgMsg.GetIndex() = 1 then
            return true
          else if dlgMsg.GetIndex() = 2 then
            return false
          end if
        else if dlgMsg.isScreenClosed()
          return false
        end if
      end if
    end while
End Function

Function interface_keyboardEntry(title as String, default as String, message as String) as Dynamic
    ' Create Dialog
    keyboardscreen = CreateObject("roKeyboardScreen")
    keyboardport = CreateObject("roMessagePort")
    keyboardscreen.SetMessagePort(keyboardport)
    keyboardscreen.SetTitle(title)
    keyboardscreen.SetText(default)
    keyboardscreen.SetDisplayText(message)
    keyboardscreen.SetMaxLength(50)
    keyboardscreen.AddButton(1, "OK")
    keyboardscreen.AddButton(2, "Back")
    keyboardscreen.Show()
  
    ' Wait for a button press
    while true
      msg = wait(0, keyboardscreen.GetMessagePort())
      print msg
      if type(msg) = "roKeyboardScreenEvent" then
        if msg.isScreenClosed() then
          return invalid
        else if msg.isButtonPressed() then
          if msg.GetIndex() = 1 then
            return keyboardscreen.GetText()
          else if msg.GetIndex() = 2 then
            return invalid
          else
            print "Invalid Index"
          endif
        endif
      endif
    end while

End Function

Function interface_listScreen(title as String, breadcrumb1 as String, breadcrumb2 as String, header as String, list as Dynamic) as Dynamic

  currentitemid = 0
  port = CreateObject("roMessagePort")
  screen = CreateObject("roListScreen")
  screen.SetMessagePort(port)
  screen.setTitle(title)
  screen.setHeader(header)
  screen.setBreadcrumbText(breadcrumb1, breadcrumb2)
  screen.SetContent(list)
  screen.Show()

  while true
    msg = wait(0, screen.GetMessagePort())
    action = invalid
    if type(msg) = "roListScreenEvent"
      if msg.isScreenClosed() then
        action = "back"
      else if msg.isScreenClosed()
        return false
      else if msg.isListItemSelected()
        action = "selected"
      else if msg.GetType() = 7
        if msg.getIndex() = 4
          action = "left"
        else if msg.getIndex() = 5
          action = "right"
        else
          print "Unknown Button Press: "; msg.getIndex()
        end if
      else if msg.GetType() = 4
        ' We have a roListScreen Index Change
        print "List index changed to "; msg.getIndex()
        currentitemid = msg.getIndex()
      else
        print "Unknown event: msgType: "; msg.GetType(); " msg: "; msg.GetMessage(); " msgIndex: "; msg.getIndex(); " msgData: "; msg.getData()
      endif
    else
      print "wrong type.... msgType: "; msg.GetType(); " msg: "; msg.GetMessage(); " msgIndex: "; msg.getIndex(); " msgData: "; msg.getData()
    endif
    if action <> invalid then
      print msg.getIndex()
      print list
      print action

      object = invalid
      print type(list)
      if type(list) = "roArray" then
        object = list[currentitemid]
      end if

      return {
        action : action
        object : object
      }
    end if
  end while

End Function

Function interface_displayVideoInfo(breadcrumb1 as String, breadcrumb2 as String, file as String) as String
  urlobj = CreateObject("roUrlTransfer")
  port = CreateObject("roMessagePort")
  springBoard = CreateObject("roSpringboardScreen")
  springBoard.SetMessagePort(port)
  springBoard.SetBreadcrumbText(breadcrumb1,breadcrumb2)
  ' Pull in data for the object :)
  metadata = shared_getURLJSON(m.serverURL + "?action=fileinfo&path=" + urlobj.Escape(file))
  if metadata = invalid then
    interface_notifyDialog("Server Error", "Unable to pull video metadata!")
  end if
  print type(metadata)
  if type(metadata) <> "roAssociativeArray" then
    interface_notifyDialog("Server Error", "Unable to pull Video Metadata! Invalid JSON Response")
  end if

  if metadata.ContentType = invalid then
    metadata.ContentType = "episode"
  end if
  if metadata.ResumeTime <> invalid then
    springBoard.AddButton(2,"Resume Video (" + metadata.ResumeTime + ")")
    springBoard.AddButton(1,"Restart Video")
  else
    springBoard.AddButton(1,"Play Video")
  end if
  while true
    springBoard.SetContent(metadata)
    springBoard.Show()
    msg = wait(0, port)
    If msg.isScreenClosed() Then
      return ""
    Else if msg.isButtonPressed()
      if msg.GetIndex() = 1 then
        return "play"
      else if msg.GetIndex() then
        return "resume"
      end if
    Endif
  end while
End Function

Function interface_displayVideo(title As string, filepath As dynamic) as Boolean
    ' Create object for urlencode
    urlobj = CreateObject("roUrlTransfer")

    print "Displaying video: " + filepath
    p = CreateObject("roMessagePort")
    video = CreateObject("roVideoScreen")
    video.setMessagePort(p)

    bitrates  = [0]    
    
    videoclip = CreateObject("roAssociativeArray")
    videoclip.StreamBitrates = bitrates
    videoclip.StreamUrls = [m.serverURL + "?action=stream_hls_m3u8&path=" + urlobj.Escape(filepath)]
    videoclip.StreamQualities = "[HD]"
    videoclip.StreamFormat = "hls"
    videoclip.SubtitleUrl = m.serverURL + "?action=stream_hls_caption&path=" + urlobj.Escape(filepath)
    videoclip.Title = title
    
    video.SetContent(videoclip)
    video.show()

    lastSavedPos   = 0
    statusInterval = 5 'position must change by more than this number of seconds before saving

    while true
        msg = wait(0, video.GetMessagePort())
        if type(msg) = "roVideoScreenEvent"
            if msg.isScreenClosed() then 'ScreenClosed event
                print "Closing video screen"
                exit while
            else if msg.isPlaybackPosition() then
                nowpos = msg.GetIndex()
                if nowpos > 0
                    if abs(nowpos - lastSavedPos) > statusInterval
                        ' Save the current position for the user to continue
                        lastSavedPos = nowpos
                    end if
                end if
            else if msg.isRequestFailed()
                print "play failed: "; msg.GetMessage()
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
            endif
        end if
    end while
End Function