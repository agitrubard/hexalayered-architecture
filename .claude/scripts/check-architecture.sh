#!/usr/bin/env sh
# ---------------------------------------------------------------------------
# check-architecture.sh — HexaLayered Architecture constitution checker
#
# Mechanically verifies Articles I, II, IV, V and VI of .claude/constitution.md
# against Java sources.
#
# Usage:
#   check-architecture.sh <file.java> [<file.java> ...]   check specific files
#   check-architecture.sh --all                           scan the whole source tree
#   check-architecture.sh                                 read a Claude Code hook
#                                                         payload (JSON) from stdin
#
# Exit codes:
#   0  clean, or nothing checkable (fails OPEN by design)
#   2  at least one violation — report is written to stderr so that, when run as
#      a PostToolUse hook, Claude Code feeds it straight back to the model
#
# POSIX sh. No dependencies beyond grep/sed/find. Safe to run anywhere.
# ---------------------------------------------------------------------------

set -u

SOURCE_ROOT="${HEXA_SOURCE_ROOT:-src/main/java}"
VIOLATIONS=0
REPORT=""

# Package path segments that denote a layer rather than a module.
LAYER_SEGMENTS=" controller service impl port adapter repository model entity enums mapper request response exception handler util config configuration security filter validation logging scheduler client "

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

report() {
    # report <article> <file> <problem> <fix>
    VIOLATIONS=$((VIOLATIONS + 1))
    REPORT="${REPORT}
  [Article $1] $2
      problem: $3
      fix:     $4"
}

# Path of the file relative to SOURCE_ROOT, or empty when it is not under it.
relative_source_path() {
    case "$1" in
        *"/$SOURCE_ROOT/"*) printf '%s' "${1##*"/$SOURCE_ROOT/"}" ;;
        "$SOURCE_ROOT/"*)   printf '%s' "${1#"$SOURCE_ROOT/"}" ;;
        *)                  printf '' ;;
    esac
}

# Declared package of a Java file.
declared_package() {
    sed -n 's/^[[:space:]]*package[[:space:]]\{1,\}\([a-zA-Z0-9_.]*\)[[:space:]]*;.*/\1/p' "$1" 2>/dev/null | head -n 1
}

# Does the file declare the given top-level type as public?
is_public_type() {
    # is_public_type <file> <ClassName>
    grep -qE "^public[[:space:]]+((final|abstract|sealed|non-sealed)[[:space:]]+)*(class|interface|record|enum)[[:space:]]+$2\b" "$1" 2>/dev/null
}

# Does the file declare the given top-level type at all (any visibility)?
declares_type() {
    grep -qE "^[[:space:]]*(public[[:space:]]+)?((final|abstract|static|sealed|non-sealed)[[:space:]]+)*(class|interface|record|enum)[[:space:]]+$2\b" "$1" 2>/dev/null
}

# Is the declared top-level type an interface?
is_interface() {
    grep -qE "^[[:space:]]*(public[[:space:]]+)?(sealed[[:space:]]+)?interface[[:space:]]+$2\b" "$1" 2>/dev/null
}

# Every `import a.b.C;` line, one per line, statics excluded.
imports_of() {
    sed -n 's/^[[:space:]]*import[[:space:]]\{1,\}\([a-zA-Z0-9_.]*\)[[:space:]]*;.*/\1/p' "$1" 2>/dev/null
}

# Trailing layer segments of a package, stripped: what remains ends with the module.
# e.g. dev.app.ticket.port.adapter -> dev.app.ticket
module_package_of() {
    _pkg="$1"
    while :; do
        _last="${_pkg##*.}"
        case "$_pkg" in *.*) ;; *) break ;; esac
        case "$LAYER_SEGMENTS" in
            *" $_last "*) _pkg="${_pkg%.*}" ;;
            *) break ;;
        esac
    done
    printf '%s' "$_pkg"
}

# ---------------------------------------------------------------------------
# per-file checks
# ---------------------------------------------------------------------------

check_file() {
    file="$1"

    case "$file" in *.java) ;; *) return 0 ;; esac
    [ -f "$file" ] || return 0

    rel=$(relative_source_path "$file")
    [ -n "$rel" ] || return 0                       # not production Java — skip

    base="${file##*/}"
    class="${base%.java}"
    [ "$class" = "package-info" ] && return 0
    [ "$class" = "module-info" ] && return 0

    pkg=$(declared_package "$file")
    [ -n "$pkg" ] || return 0                       # unparseable — fail open

    module_pkg=$(module_package_of "$pkg")
    module="${module_pkg##*.}"

    # -- Article V: package path must agree with the declared package ---------
    dir_pkg=$(printf '%s' "${rel%/*}" | tr '/' '.')
    if [ "$rel" != "${rel%/*}" ] && [ "$dir_pkg" != "$pkg" ]; then
        report V "$file" \
            "declared package '$pkg' does not match its directory '$dir_pkg'" \
            "move the file to $SOURCE_ROOT/$(printf '%s' "$pkg" | tr '.' '/')/ or fix the package statement"
    fi

    # -- Articles IV + V: role, package suffix and visibility -----------------
    case "$class" in

        *ServiceImpl)
            case "$pkg" in
                *.service.impl) ;;
                *) report V "$file" \
                        "'$class' is a service implementation but lives in '$pkg'" \
                        "move it to ${module_pkg}.service.impl" ;;
            esac
            if is_public_type "$file" "$class"; then
                report IV "$file" \
                    "'$class' is public" \
                    "make it package-private: 'class $class implements ...' — only the Service interface is public"
            fi
            iface="${class%Impl}"
            if ! grep -qE "implements[^{]*\b${iface}\b" "$file" 2>/dev/null; then
                report III "$file" \
                    "'$class' does not implement an interface named '$iface'" \
                    "declare 'public interface $iface' in ${module_pkg}.service and implement it"
            fi
            ;;

        *Service)
            case "$pkg" in
                *.service) ;;
                *) report V "$file" \
                        "'$class' is a service contract but lives in '$pkg'" \
                        "move it to ${module_pkg}.service" ;;
            esac
            if declares_type "$file" "$class"; then
                if ! is_interface "$file" "$class"; then
                    report III "$file" \
                        "'$class' is a class, not an interface" \
                        "services are contracts: 'public interface $class', with the logic in ${class}Impl"
                elif ! is_public_type "$file" "$class"; then
                    report IV "$file" \
                        "interface '$class' is not public" \
                        "make it 'public interface $class' — controllers in other packages must see it"
                fi
            fi
            ;;

        *Adapter)
            case "$pkg" in
                *.port.adapter) ;;
                *) report V "$file" \
                        "'$class' is an adapter but lives in '$pkg'" \
                        "move it to ${module_pkg}.port.adapter" ;;
            esac
            if is_public_type "$file" "$class"; then
                report IV "$file" \
                    "'$class' is public" \
                    "make it package-private: 'class $class implements ...Port' — only the Port is public"
            fi
            if ! grep -qE "implements[^{]*Port\b" "$file" 2>/dev/null; then
                report III "$file" \
                    "'$class' implements no '*Port' interface" \
                    "every adapter is the implementation of one or more ports in ${module_pkg}.port"
            fi
            ;;

        *Port)
            case "$pkg" in
                *.port) ;;
                *) report V "$file" \
                        "'$class' is a port but lives in '$pkg'" \
                        "move it to ${module_pkg}.port" ;;
            esac
            if declares_type "$file" "$class"; then
                if ! is_interface "$file" "$class"; then
                    report III "$file" \
                        "'$class' is a class, not an interface" \
                        "ports are contracts: 'public interface $class', implemented by ${class%Port}Adapter"
                elif ! is_public_type "$file" "$class"; then
                    report IV "$file" \
                        "interface '$class' is not public" \
                        "make it 'public interface $class' — service implementations in other packages must see it"
                fi
            fi
            ;;

        *Controller)
            case "$pkg" in
                *.controller) ;;
                *) report V "$file" \
                        "'$class' is a controller but lives in '$pkg'" \
                        "move it to ${module_pkg}.controller" ;;
            esac
            if is_public_type "$file" "$class"; then
                report IV "$file" \
                    "'$class' is public" \
                    "make it package-private: '@RestController class $class' — nothing may depend on a controller"
            fi
            ;;

        *Repository)
            case "$pkg" in
                *.repository) ;;
                *) report V "$file" \
                        "'$class' is a repository but lives in '$pkg'" \
                        "move it to ${module_pkg}.repository" ;;
            esac
            if declares_type "$file" "$class" && ! is_public_type "$file" "$class"; then
                report IV "$file" \
                    "'$class' is not public" \
                    "make it 'public interface $class extends JpaRepository<...>'"
            fi
            ;;

        *Entity)
            case "$pkg" in
                *.model.entity) ;;
                *) report V "$file" \
                        "'$class' is an entity but lives in '$pkg'" \
                        "move it to ${module_pkg}.model.entity" ;;
            esac
            ;;

        *Request)
            case "$pkg" in
                *.model.request|*.model) ;;
                *) report V "$file" \
                        "'$class' is a request model but lives in '$pkg'" \
                        "move it to ${module_pkg}.model.request" ;;
            esac
            ;;

        *Response)
            case "$pkg" in
                *.model.response|*.model) ;;
                *) report V "$file" \
                        "'$class' is a response model but lives in '$pkg'" \
                        "move it to ${module_pkg}.model.response" ;;
            esac
            ;;

        *Mapper)
            case "$pkg" in
                *.model.mapper) ;;
                *) report V "$file" \
                        "'$class' is a mapper but lives in '$pkg'" \
                        "move it to ${module_pkg}.model.mapper" ;;
            esac
            ;;

        *Exception)
            case "$pkg" in
                *.exception) ;;
                *) report V "$file" \
                        "'$class' is an exception but lives in '$pkg'" \
                        "move it to ${module_pkg}.exception" ;;
            esac
            ;;

        *Util)
            case "$pkg" in
                *.util) ;;
                *) report V "$file" \
                        "'$class' is a utility but lives in '$pkg'" \
                        "move it to ${module_pkg}.util" ;;
            esac
            ;;
    esac

    # -- Articles I, II, VI: what this file is allowed to import --------------
    #
    # Which layer are we in? Determined from the package suffix.
    layer=other
    case "$pkg" in
        *.controller)   layer=controller ;;
        *.service.impl) layer=serviceimpl ;;
        *.service)      layer=service ;;
        *.port.adapter) layer=adapter ;;
        *.port)         layer=port ;;
        *.repository)   layer=repository ;;
        *.model.mapper) layer=mapper ;;
        *.model.entity) layer=entity ;;
        *.model|*.model.request|*.model.response|*.model.enums) layer=model ;;
    esac

    # Iterate with `for`, not `imports_of | while`: a pipeline body runs in a subshell, so
    # every report() from inside it would be discarded. Import lines are single tokens with
    # no spaces, so unquoted word splitting is exactly right here.
    for imp in $(imports_of "$file"); do
        [ -n "$imp" ] || continue
        simple="${imp##*.}"
        imp_module_pkg=$(module_package_of "$imp")

        # --- Article II: entity containment ---------------------------------
        case "$imp" in
            *.model.entity.*)
                case "$layer" in
                    controller|service|serviceimpl|port|model)
                        report II "$file" \
                            "a $layer type imports the entity '$simple' ($imp)" \
                            "entities never leave the persistence edge — take/return the domain model instead, and map inside the adapter" ;;
                esac
                ;;
        esac

        # --- Article I: repository access is adapter-only --------------------
        case "$simple" in
            *Repository)
                case "$layer" in
                    controller|service|serviceimpl|port)
                        report I "$file" \
                            "a $layer type imports the repository '$simple'" \
                            "go through a Port: ${layer%impl} → *Port → *Adapter → $simple" ;;
                esac
                ;;
        esac

        # --- Article I: no upward dependencies ------------------------------
        case "$simple" in
            *Controller)
                case "$layer" in
                    service|serviceimpl|port|adapter|repository|entity|model|mapper)
                        report I "$file" \
                            "a $layer type imports the controller '$simple' — dependencies point inward only" \
                            "move the shared type down into ${module_pkg}.model or ${module_pkg}.util" ;;
                esac
                ;;
        esac

        # --- Article I / IV: never depend on an implementation --------------
        case "$imp" in
            *.service.impl.*)
                report I "$file" \
                    "imports the service implementation '$simple'" \
                    "depend on the ${simple%Impl} interface in ${imp_module_pkg}.service instead" ;;
            *.port.adapter.*)
                report I "$file" \
                    "imports the adapter '$simple'" \
                    "depend on the Port interface in ${imp_module_pkg}.port instead" ;;
        esac

        # --- Article VI: module isolation -----------------------------------
        # Only judge imports that live under the same base package and belong to
        # a *different* module. 'common' is the shared module and is exempt.
        if [ -n "$module_pkg" ] && [ "$imp_module_pkg" != "$module_pkg" ]; then
            imp_module="${imp_module_pkg##*.}"
            if [ "${imp_module_pkg%.*}" = "${module_pkg%.*}" ] && [ "$imp_module" != "common" ]; then
                case "$imp" in
                    *.repository.*)
                        report VI "$file" \
                            "module '$module' reaches into '$imp_module' internals: $imp" \
                            "expose the behaviour from '$imp_module' as a public Port or Service and depend on that" ;;
                esac
            fi
        fi
    done

    return 0
}

# ---------------------------------------------------------------------------
# input handling
# ---------------------------------------------------------------------------

collect_all() {
    [ -d "$SOURCE_ROOT" ] || return 0
    find "$SOURCE_ROOT" -name '*.java' -type f 2>/dev/null
}

# Extract "file_path" from a Claude Code hook JSON payload on stdin.
file_path_from_hook_payload() {
    payload=$(cat 2>/dev/null)
    [ -n "$payload" ] || return 0
    printf '%s' "$payload" \
        | tr ',' '\n' \
        | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
        | head -n 1
}

FILES=""
case "${1:-}" in
    --all|-a)
        FILES=$(collect_all)
        ;;
    --help|-h)
        sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
        exit 0
        ;;
    "")
        if [ -t 0 ]; then
            FILES=$(collect_all)
        else
            FILES=$(file_path_from_hook_payload)
        fi
        ;;
    *)
        FILES=$(printf '%s\n' "$@")
        ;;
esac

[ -n "$FILES" ] || exit 0

# The `while read` loop above runs in a subshell in POSIX sh, so accumulate the
# whole report in a temp file rather than in shell variables.
TMP_REPORT=$(mktemp 2>/dev/null || printf '/tmp/hexa-check-%s' "$$")
: > "$TMP_REPORT"

printf '%s\n' "$FILES" | while IFS= read -r f; do
    [ -n "$f" ] || continue
    (
        VIOLATIONS=0
        REPORT=""
        check_file "$f"
        [ "$VIOLATIONS" -gt 0 ] && printf '%s\n' "$REPORT" >> "$TMP_REPORT"
        exit 0
    )
done

if [ -s "$TMP_REPORT" ]; then
    {
        echo "HEXALAYERED CONSTITUTION VIOLATION"
        echo
        cat "$TMP_REPORT"
        echo
        echo "  Fix these before continuing. Full rules: .claude/constitution.md"
        echo "  Layer reference:                        .claude/skills/hexalayered-architecture/references/layers.md"
    } >&2
    rm -f "$TMP_REPORT"
    exit 2
fi

rm -f "$TMP_REPORT"
exit 0
