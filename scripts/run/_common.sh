#!/usr/bin/env bash
# Shared helpers for the run scripts. Usage (inside a script):
#     source scripts/run/_common.sh <case_dir>
# Exposes: CASE_DIR, RUN_DIR, WPS_RUN, WRF_RUN and the variables in case.conf.

_case="${1:?usage: source _common.sh <case_dir>}"
CASE_DIR="$(cd "$_case" && pwd)"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_DIR/env/sooner_wrf.env.sh"
source "$CASE_DIR/case.conf"

RUN_DIR="$RUNS_DIR/$CASE_NAME"
WPS_RUN="$RUN_DIR/wps"
WRF_RUN="$RUN_DIR/wrf"

# "2013-05-20_12" -> pieces + WPS-format "2013-05-20_12:00:00"
_split() { local s="$1"; echo "${s:0:4} ${s:5:2} ${s:8:2} ${s:11:2}"; }
read -r SY SM SD SH <<< "$(_split "$START")"
read -r EY EM ED EH <<< "$(_split "$END")"
START_DATE="${START}:00:00"
END_DATE="${END}:00:00"
RUN_HOURS=$(( ( $(date -u -d "$EY-$EM-$ED $EH:00" +%s) - $(date -u -d "$SY-$SM-$SD $SH:00" +%s) ) / 3600 ))

# Fill @TOKENS@ in a namelist template.
fill_template() {   # fill_template <template> <output> [extra sed args...]
    local src="$1" dst="$2"; shift 2
    sed -e "s|@START_DATE@|$START_DATE|g" -e "s|@END_DATE@|$END_DATE|g" \
        -e "s|@INTERVAL@|$INTERVAL_SECONDS|g" -e "s|@GEOG_DIR@|$GEOG_DIR|g" \
        -e "s|@RUN_HOURS@|$RUN_HOURS|g" \
        -e "s|@SY@|$SY|g" -e "s|@SM@|$SM|g" -e "s|@SD@|$SD|g" -e "s|@SH@|$SH|g" \
        -e "s|@EY@|$EY|g" -e "s|@EM@|$EM|g" -e "s|@ED@|$ED|g" -e "s|@EH@|$EH|g" \
        "$@" "$src" > "$dst"
}

# bash replacement for WPS's link_grib.csh (no csh dependency)
link_grib() {       # link_grib <dir-with-grib-files>
    rm -f GRIBFILE.???
    local letters=(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)
    local i=0 f
    for f in "$1"/*; do
        [ -f "$f" ] || continue
        local a=${letters[$((i/676%26))]} b=${letters[$((i/26%26))]} c=${letters[$((i%26))]}
        ln -sf "$f" "GRIBFILE.$a$b$c"; i=$((i+1))
    done
    echo "linked $i GRIB files"
}
