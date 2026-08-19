# Parse an md table from raw input
export def 'from table' [
]: [
  string -> table
] {
  $in | lines | str replace -r '^\||\|$' '' -a | split column '|' | headers | skip 1
}
