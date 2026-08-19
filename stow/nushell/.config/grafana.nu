
export def parse []: int -> int  {
    $in | get fields  | select -i ts level Message exceptionMessage exceptionStackTrace exceptionTargetSite  exceptionType | where ts != null | sort-by ts | update level {|r| $"(if ($r.level == error) { ansi red } else if ($r.level == info) { ansi blue } else if ($r.level == warn) { ansi yellow })($r.level)(ansi reset)"} }
