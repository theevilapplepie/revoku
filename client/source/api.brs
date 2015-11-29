Function api_getServerInfo(serverURL as String) as Dynamic
  if serverURL = invalid then
    return false
  else if serverURL = ""
    return false
  end if
  return shared_getURLJSON(serverURL + "?action=serverinfo")
End Function