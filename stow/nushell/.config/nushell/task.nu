
export-env {$env.TASKS_DIR = "C:\\Users\\DATAAAL\\Tasks"}

def base_path [name: string] : nothing -> string {
return ([$env.TASKS_DIR $"($name)"] | path join)
}

export def create [base: string, name: string, --no_dir] : any -> any {
  let the_path = base_path $base
  if (not $no_dir) {
    mkdir ($the_path)
  }
  let file_name = ([$the_path $"($name).md"] | path join)
  touch $file_name
  return  $file_name
}

export def edit [base: string, name: string] : nothing -> nothing {
  let base_path = ([$env.TASKS_DIR $base] | path join)
  #print $base_path
  #print $name
  let names = (ls -s $base_path | select name )

  #print $names

  
  if (($names | where name == $name | length) == 1) {
    run-external $env.EDITOR ([$base_path $"($names | where name == $name | get name.0)"] | path join)
  } else {
    let found = ($names | find -n $name)
    let count = ($found | length)
    #print $count
    let task_name = match $count { 
      0 => (create $base $name --no_dir),
      1 => ($found | get name.0),
      _ => ($found | select name | input list "Multiple matchs:" | get name)
    }

    run-external $env.EDITOR ([$base_path $"($task_name)"] | path join)
  }
}

export def 'git notes' [] : nothing -> nothing {
  let branch_name = (^git rev-parse --abbrev-ref HEAD | str replace "/" "_" |  str replace "\\" "_" )
  let base_name = (pwd | path basename)

  if ((ls -s $env.TASKS_DIR | select name  | where name == $branch_name | length) == 0) {
    create $base_name $branch_name
  }

  edit $base_name $branch_name
}

export def 'git path' [] : nothing -> string {
  let base = (pwd | path basename)
  let the_path = base_path $base
  return $the_path
}

export def "path git" [] : nothing -> string {
  return (base_path (^git rev-parse --abbrev-ref HEAD | str replace "/" "_" |  str replace "\\" "_" ))
}
