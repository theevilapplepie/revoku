Function audioplayer_displayVideo(title As string, filepath As dynamic) as Boolean
    ' Create object for urlencode
    urlobj = CreateObject("roUrlTransfer")

    print "Displaying video: " + filepath
    p = CreateObject("roMessagePort")
    video = CreateObject("roVideoScreen")
    video.setMessagePort(p)

    bitrates  = [0]    
    
    videoclip = CreateObject("roAssociativeArray")
    videoclip.StreamBitrates = bitrates
    videoclip.StreamUrls = [m.serverURL + "?action=stream_hls_m3u8_audio&path=" + urlobj.Escape(filepath)]
    videoclip.StreamQualities = "[HD]"
    videoclip.StreamFormat = "hls"
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

Sub audioplayer_player(breadcrumb1 as String, breadcrumb2 as String, file as String)

  print "OMG FILE: " + file

  ' Create Objects
  urlobj = CreateObject("roUrlTransfer")
  port = CreateObject("roMessagePort")
  springBoard = CreateObject("roSpringboardScreen")
  audioPlayer = CreateObject("roAudioPlayer")

  ' Setup Audio
  audioPlayer.SetMessagePort(port)
  song = CreateObject("roAssociativeArray")
  audioplayer.setloop(false)

  ' Setup Springboard
  springBoard.SetMessagePort(port)
  springBoard.SetBreadcrumbText(breadcrumb1,breadcrumb2)
  springBoard.setProgressIndicatorEnabled(true)
  springBoard.SetDescriptionStyle("audio")

  ' Pull in data for the object :)
  metadata = shared_getURLJSON(m.serverURL + "?action=audioinfo&path=" + urlobj.Escape(file))
  if metadata = invalid then
    interface_notifyDialog("Server Error", "Unable to pull video metadata!")
  end if
  if type(metadata) <> "roAssociativeArray" then
    interface_notifyDialog("Server Error", "Unable to pull Video Metadata! Invalid JSON Response")
  end if
  metadata.contenttype = "audio"
  metadata.url = m.serverURL + "?action=stream_hls_m3u8_audio&path=" + urlobj.Escape(file)
  metadata.streamformat = "hls"

  ' Lets start up the "player"
  audioplayer.addcontent(metadata)
  audioPlayer.play()

  ' Main Loop
  playmode = "once"
  while true

    ' Update buttons to situation
    springBoard.clearButtons()
    if playmode = "once" then
      springBoard.AddButton(1,"Play Mode: Play Once")
    else if playmode = "repeat" then
      springBoard.AddButton(1,"Play Mode: Repeat")
    end if
    springBoard.AddButton(2,"Directory Play - Start Here")

    ' Show Springboard'
    springBoard.SetContent(metadata)
    springBoard.Show()
    springBoard.setProgressIndicator(250, 1000)

    msg = wait(0, port)
    if type(msg) = "roAudioPlayerEvent"
      print "wrong type.... msgType: "; msg.GetType(); " msg: "; msg.GetMessage(); " msgIndex: "; msg.getIndex(); " msgData: "; msg.getData()
    else if type(msg) = "roSpringboardScreenEvent"
      if msg.isScreenClosed() then
        return
      else if msg.isScreenClosed()
        return
      else if msg.GetType() = 7
        if msg.getIndex() = 4
          print "left"
        else if msg.getIndex() = 5
          print "right"
        else
          print "Unknown Button Press: "; msg.getIndex()
        end if
      else
        print "Unknown event: msgType: "; msg.GetType(); " msg: "; msg.GetMessage(); " msgIndex: "; msg.getIndex(); " msgData: "; msg.getData()
      endif
    else
      print "wrong type.... msgType: "; msg.GetType(); " msg: "; msg.GetMessage(); " msgIndex: "; msg.getIndex(); " msgData: "; msg.getData()
    endif
  end while
End Sub
