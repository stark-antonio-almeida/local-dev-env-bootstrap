# Create and Add C# project
export def create [
  name: string, # Name of the project
  type?: string  # Type of the project
]: [
  nothing -> nothing
] {
  let the_list = list templates;
  mut call_add = false
  let type_arg = if ($type == null) {
    let tmp_type = ($the_list | input list )
    $call_add = $tmp_type | get Language | str contains "C#"
    ($tmp_type | get 'Short Name')
  } else {
    let tmp_list = $the_list | where { |l| (($l | get -o 'Short Name' | default " " ) | into string) =~ $type }
    if ( ($tmp_list | length) == 0) {
      let span = (metadata $tmp_list).span;
      error make {
        msg: "No templates match",
        label: {
          text: $"where matched no 'Sort Name': ($type)",
            span: $span
        }
      }
    }
    $call_add = $tmp_list | get 0.Language | str contains "C#"
    $type
  }

  ^dotnet new $type_arg  -n $name 
  if $call_add {
    $"($name)/($name).csproj" | add
  }
}

# List Projects
export def "list templates" [
]: [
  nothing -> list
] {
  (^dotnet new list | lines | skip 2 | split column --collapse-empty --regex '\s\s+' | headers | skip 1)
}


# List Projects
export def "list sln" [
]: [
  nothing -> list
] {
  (^dotnet sln list | lines | skip 2)
}

# List Projects
export def "list all" [
]: [
  nothing -> list
] {
  (ls ...(glob $"**/*.csproj") | get name  | each { |p| $p | path relative-to (pwd) })
}

# Add Project(s) to solution
export def add [
  ...names: string,
  --dry_run
]: [
  any -> nothing

] {

  let the_input = $in
  let the_input_type = ($the_input | describe)
  let to_add = if (($the_input_type == "nothing") and ($names | is-empty)) {
    ((list all) | where {|p| $p not-in (list sln)} | input list --multi)
  } else if ($the_input_type == "list<string>") { 
    $the_input
  } else if ($the_input_type == "string") { 
    [$the_input]
  } else {
    $names
  }

  if ($dry_run) {
    print ($"^dotnet sln add ($to_add | str join ' ')")
  } else {
    ^dotnet sln add ...$to_add
  }
}

# Remove Project(s) from solution
export def remove [
  --dry_run
]: [
  any -> nothing
] {
  let the_input = $in
  let the_input_type = ($the_input | describe )
  let $to_remove = if ($the_input_type == "nothing") {
    (list sln | input list --multi)
  } else if ($the_input_type == "list<string>") { 
    $the_input
  } else if ($the_input_type == "string") { 
    [$the_input]
  } else {
    return
  }

  if ($dry_run) {
    print ($"^dotnet sln remove ($to_remove | str join ' ')")
  } else {
    ^dotnet sln remove ...$to_remove 
  }
}

# Build all
export def "build all"  [
  --no_warn (-w)
]: [
  nothing -> nothing
] {
  ls ...(glob $"**/*.csproj") | get name | each { |p| let proj = ($p | into string); {name: ($proj | path basename), build: (if $no_warn {(^dotnet clean $proj -v q; ^dotnet build $proj -v q --property WarningLevel=0)} else { (^dotnet clean $proj -v q; ^dotnet build $proj -v q)})}}
}

export def "publish self-contained" [ path: string ] : nothing -> nothing {
  ^dotnet publish --configuration Release -o $path -r win-x64  -p:PublishSingleFile=true -p:PublishTrimmed=true --self-contained true
}
