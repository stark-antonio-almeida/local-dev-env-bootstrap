# This is a simple todo list tool
# It uses a file (essentially a yaml list) to store quick notes
# The last command output is automatically store on the variable '$env.TODOS_LAST_RESULT'
# Allow listing, adding searching and completing tasks
# Use the 'help todo' or 'todo <command> -h' to learn more

export-env {$env.TODOS_LAST_RESULT = []}
 
def --env export-return [] : any -> any {
  let export_todo = $in
  export-env {$env.TODOS_LAST_RESULT = $export_todo}
  return $export_todo
}

def select-multiple [] : table -> table {
  let the_table = $in
  return ($the_table | (if (($in | length) > 1) {$in | insert tmp {|r| [$r.id ": " $r.summary] | str join }| input list --multi 'Select tasks wih space key, confim wiht enter key, abort with q or esc' -d tmp | try {reject -o tmp} } else {$in}));
}

def select-single [] : table -> table {
  let the_table = $in
  return ($the_table | (if (($in | length) > 1) {$in | insert tmp {|r| [$r.id ": " $r.summary] | str join }| input list 'Select tasks wih space key, confim wiht enter key, abort with q or esc' -d tmp | try {reject -o tmp} } else {$in}));
}

def full-fields [full: bool, hide_done: bool = false] : table -> table {
  let $the_table = $in
  return (if ($hide_done) {
    $the_table | if ($full) { $in | reject done } else {$in | select id summary date updated};
  } else {
    $the_table | update done { if ($in == true) { "✅"} else {"⏳"}} | if ($full) { $in } else {$in | select id done summary date updated};
  }) | update date { into datetime } | update updated { if ($in == null) {''} else { $in | into datetime} };
}

def tags-list [] {
  open $"($env.TODO_MAIN_FILE)" -r | from yaml | get tags | flatten | uniq;
}

# List TODOs
export def --env list [
  --all (-a) # Return all. By default show not done
  --full (-f) # Return all columns
] : nothing -> table {
  let the_list = open $"($env.TODO_MAIN_FILE)" -r | from yaml;
  if ($the_list == null) {
    return [];
  }
  return ((if $all {
    $the_list | full-fields $full;
  } else {
    $the_list |  where done == false | full-fields $full true;
  }) | export-return )
}

# Search a entries on the TODOs list
# If multiple matches are wound a list input picker is prompted
export def --env fuzzy [
  id?: string # the id or summary or a subset of it (might return multiples)
] : [
    string -> table
    nothing -> table
   ] {

  if ($id == null and $in == null) {
    return;
  }

  let d_id = match ($in | describe) {
    'string' => $in,
    _ => $id
  }

  let the_list = open $"($env.TODO_MAIN_FILE)" -r | from yaml;

  return ($the_list | find $d_id | select-multiple | full-fields true | export-return);
}

# Get (search) an entry of the TODOs list
export def --env by-tag [
  tag?: string  # the tag or subset of it (might return multiples)
  --select (-s) # prompt an input list to select from existing
] : [
    string -> table
    nothing -> table
   ] {
   
  if ($tag == null and $in == null and not $select) {
    return;
  }

  let d_tag = match ($in | describe) {
    'string' => $tag,
    _ => (if ($select) {tags-list | input list "Pick a tag"} else { $tag })
  }

  let the_list = open $"($env.TODO_MAIN_FILE)" -r | from yaml;

   return ($the_list | where {|row| ($row.tags | any { |t| $t =~ $d_tag })} | full-fields true | export-return );
  }

# Add an entry to the TODOs list
export def --env add [
  --done (-d), # mark as done
  --links (-l): list, # add links
  --tags (-t): list,  # add tags
  --tag-select (-s),  # add tags selected from a list
  ...summary: string  # text to add
] : nothing -> nothing {
  let text = ($summary | str join ' ');
  let new_date = (date now);
  let id = ([$text $new_date] | str join | hash md5 | str substring ..10);
  let concat_tags = [] ++ ($tags | default []) ++ (if $tag_select {tags-list | input list -m "Pick a tag"} else {[]})
  [{id: $id, done: (if ($done) {true} else {false}), summary: $text , date: $new_date , updated: (if ($done) {date now} else {''}), tags: $concat_tags, links: ($links | default [])}] | export-return | to yaml | save $"($env.TODO_MAIN_FILE)" -a
  return $id
}

# Complete a task (marking it as done)
# Uses the id to find the desired task
# If --fuzzy is set the id argument accepts a summary excerpt for fuzzy searching
# If multiple matches are wound a list input picker is prompted
export def --env done [
  id?: string   # The id or partial id to complete.
] : [
    string -> table
    nothing -> table
   ] {
  if ($id == null and $in == null) {
    return [];
  }

  let d_id = match ($in | describe) {
    'string' => $in,
    _ => $id
  }

  let the_list = open $"($env.TODO_MAIN_FILE)" -r | from yaml;

  let found = ($the_list | where { |r| ($r.id like $d_id and $r.done == false)});
  let found_count = ($found | length)

  if ($found_count == 0) {
    return ( [] | export-return )
  }

  let selected_id = (if ($found_count == 1) {
    ($found | get 0.id)
  } else {
    ($found | select-single | get id)
  });

   let update_list = $the_list | update updated { |r| if ($r.id == $selected_id and $r.done == false) { date now } else {$r.updated} } | update done { |r| if ($r.id == $selected_id) { true } else {$r.done} };
   $update_list | to yaml | save $"($env.TODO_MAIN_FILE)" -f
   return ($update_list | where id == $selected_id | full-fields true | export-return );
}
