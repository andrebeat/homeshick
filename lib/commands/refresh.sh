#!/bin/bash


function refresh {
	[[ ! $1 || ! $2 ]] && help_err last-update
	local threshhold=$1
	local castle=$2
	local fetch_head="$repos/$castle/.git/FETCH_HEAD"
	pending 'checking' "$castle"
	castle_exists 'check freshness' "$castle"

	if [[ -e $fetch_head ]]; then
		local last_mod=$(stat -c %Y "$fetch_head" 2> /dev/null || stat -f %m "$fetch_head")
		local time_now=$(date +%s)
		if [[ $((time_now-last_mod)) -gt $threshhold ]]; then
			fail "outdated"
			return $EX_TH_EXCEEDED
		else
			success "fresh"
			return $EX_SUCCESS
		fi
	else
		fail "outdated"
		return $EX_TH_EXCEEDED
	fi
}

function pull_outdated {
	local threshhold=$1; shift
	local outdated_castles=()
	while [[ $# -gt 0 ]]; do
		local castle=$1; shift
		local fetch_head="$repos/$castle/.git/FETCH_HEAD"
		# When in interactive mode:
		# No matter if we are going to pull the castles or not
		# we reset the outdated ones by touching FETCH_HEAD
		if [[ -e $fetch_head ]]; then
			local last_mod=$(stat -c %Y "$fetch_head" 2> /dev/null || stat -f %m "$fetch_head")
			local time_now=$(date +%s)
			if [[ $((time_now-last_mod)) -gt $threshhold ]]; then
				outdated_castles+=("$castle")
				! $BATCH && touch "$fetch_head"
			fi
		else
			outdated_castles+=("$castle")
			! $BATCH && touch "$fetch_head"
		fi
	done
	ask_pull ${outdated_castles[*]}
	return $EX_SUCCESS
}

function ask_pull {
	if [[ $# -gt 0 ]]; then
		if [[ $# == 1 ]]; then
			msg="The castle $1 is outdated."
		else
			OIFS=$IFS
			IFS=,
			msg="The castles $* are outdated."
			IFS=$OIFS
		fi
		prompt_no 'refresh' "$msg" 'pull?'
		if [[ $? = 0 ]]; then
			for castle in $*; do
				pull "$castle"
			done
		fi
	fi
	return $EX_SUCCESS
}