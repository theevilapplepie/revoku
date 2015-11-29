Sub shared_getURL(url as String) as String
  request = CreateObject("roUrlTransfer")
  request.SetUrl(url)
  return request.GetToString()
End Sub

Sub shared_getURLJSON(url as String) as Dynamic
  ' Get URL
  data = shared_getURL(url)
  ' Check data and JSON
  if data = "" then
    return false
  else
    ' Parse JSON
    jsonobj = ParseJSON(data)
    ' Validate if we have valid JSON
    if jsonobj <> invalid then
      ' We successfully received a JSON response!
      return jsonobj
    endif
  endif
  ' We did not have a valid JSON Object'
  return invalid
End Sub