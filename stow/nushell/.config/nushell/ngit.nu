export def --wrapped log [...args] : nothing -> list {
  ^git log ...$args --pretty=%h»¦«%aN»¦«%s»¦«%aD | lines | split column "»¦«" sha1 committer desc merged_at
} 

export def --wrapped activity [...args] : nothing -> list {
  ^git log ...$args --pretty=%h»¦«%aN»¦«%s»¦«%aD | lines | split column "»¦«" sha1 committer desc merged_at | histogram committer merger | sort-by merger | reverse
}

export def "branch list" [] : nothing -> list {
  ^git branch --format="%(if)%(HEAD)%(then)➡️ %(else)  %(end)|%(refname:short)" | lines | split column '|' * name
}

export def "branch selected" [] : nothing -> list {
  ^git branch --show-current
}
