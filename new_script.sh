#!/usr/bin/env bash

set -euo pipefail

manager="$1"

cat >"scripts/${manager}.sh" <<EOF
#!/usr/bin/env bash

install() {
    local package="\$1"

    # TODO
}

validate() {
    local command="\$1"

    eval "\$command"
}
EOF

chmod +x "scripts/${manager}.sh"

echo "Created scripts/${manager}.sh"
