Function registry_sectionWrite(section as String, keyname as String, value as string) as Boolean
  registry = CreateObject("roRegistrySection", section)
  registry.Write(keyname, value)
  return true
End Function

Function registry_sectionRead(section as String, keyname as String) as String
  registry = CreateObject("roRegistrySection", section)
  if registry.Exists(keyname) = invalid
    return invalid
  end if
  return registry.Read(keyname)
End Function

Function registry_sectionDelete(section as String, keyname as String) as Boolean
  registry = CreateObject("roRegistrySection", section)
  if registry.Exists(keyname) = invalid
    return invalid
  end if
  registry.Delete(keyname)
  return true
End Function

Function registry_sectionList(section as String) as Dynamic
  registry = CreateObject("roRegistrySection", section)
  return registry.GetKeyList()
End Function

Sub registry_Flush()
  registry = CreateObject("roRegistry")
  registry.flush()
End Sub