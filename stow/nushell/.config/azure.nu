

export def token [
  --access_token (-t), # Name of the project
  --clip (-c)
]: [
  nothing -> any
] {
  let az_access_info = (az account get-access-token --resource-type oss-rdbms | from json)
  let out = if ($access_token) {
    ($az_access_info | get accessToken)
  } else {
    $az_access_info
  }
  if ($clip) {
    $out | ^clip
    return null
  }
  
  return $out
}
