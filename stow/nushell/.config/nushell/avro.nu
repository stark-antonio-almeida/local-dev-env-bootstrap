# Get a subste of schemas based on a subject
# Explore, select (:q to exit on a selected)
# It will be saved with the flag --skip-directories
# out defines the output name
export def store [
  --user (-u): string, # Avro schema username
  --pass (-p): string, # Avro password
  subject: string,     # The topic name or a substring of it
  out: string          # The name of the generated sources 
]: [
  nothing -> nothing
] {
  schemas -u $user -p $pass | where subject =~ $subject | explore --peek | save $"($out).avsc"
}

# Get a all schemas
export def schemas [
  --user (-u): string, # Avro schema username
  --pass (-p): string, # Avro password
  --prod # if targeting prod env
]: [
  nothing -> table
] {
  http get --user $user --password $pass (if ($prod) {"https://psrc-qrk9d.westeurope.azure.confluent.cloud/schemas/" } else { "https://psrc-0j199.westeurope.azure.confluent.cloud/schemas/" } ) | from json
}

# Get a subste of schemas based on a subject
# Explore, select (:q to exit on a selected)
# It will be saved to a tmp file (this file will be removed automatically)
# out defines the output name for the generated sources
export def gen [
  --user (-u): string, # Avro schema username
  --pass (-p): string, # Avro password
  subject: string,     # The topic name or a substring of it
  out: string          # The name of the generated sources
] : [
  nothing -> nothing 
] {
  schemas -u $user -p $pass | where subject =~ $subject | explore --peek | save $"($out)_tmp.avsc" -f
  ^avrogen -s $"($out)_tmp.avsc" $"($out)" --skip-directories
  rm $"($out)_tmp.avsc"
}

