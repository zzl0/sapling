#chg-compatible

test for old histedit issue #6:
editing a changeset without any actual change would corrupt the repository

  $ . "$TESTDIR/histedit-helpers.sh"

  $ enable histedit
  $ configure modern

  $ initrepo ()
  > {
  >     dir="$1"
  >     comment="$2"
  >     if [ -n "${comment}" ]; then
  >         echo % ${comment}
  >         echo % ${comment} | sed 's:.:-:g'
  >     fi
  >     newclientrepo ${dir}
  >     for x in a b c d e f ; do
  >         echo $x > $x
  >         hg add $x
  >         hg ci -m $x
  >     done
  >     cd ..
  > }

  $ geneditor ()
  > {
  >     # generate an editor script for selecting changesets to be edited
  >     choice=$1  # changesets that should be edited (using sed line ranges)
  >     cat <<EOF | sed 's:^....::'
  >     # editing the rules, replacing 'pick' with 'edit' for the chosen lines
  >     sed '${choice}s:^pick:edit:' "\$1" > "\${1}.tmp"
  >     mv "\${1}.tmp" "\$1"
  >     # displaying the resulting rules, minus comments and empty lines
  >     sed '/^#/d;/^$/d;s:^:| :' "\$1" >&2
  > EOF
  > }

  $ startediting ()
  > {
  >     # begin an editing session
  >     choice="$1"  # changesets that should be edited
  >     number="$2"  # number of changesets considered (from tip)
  >     comment="$3"
  >     geneditor "${choice}" > edit.sh
  >     echo % start editing the history ${comment}
  >     HGEDITOR="sh ./edit.sh" hg histedit -- -${number} 2>&1 | fixbundle
  > }

  $ continueediting ()
  > {
  >     # continue an edit already in progress
  >     editor="$1"  # message editor when finalizing editing
  >     comment="$2"
  >     echo % finalize changeset editing ${comment}
  >     HGEDITOR=${editor} hg histedit --continue 2>&1 | fixbundle
  > }

  $ graphlog ()
  > {
  >     comment="${1:-log}"
  >     echo % "${comment}"
  >     hg log -G --template '{node} \"{desc|firstline}\"\n'
  > }


  $ initrepo r1 "test editing with no change"
  % test editing with no change
  -----------------------------
  $ cd r1
  $ graphlog "log before editing"
  % log before editing
  @  652413bf663ef2a641cab26574e46d5f5a64a55a "f"
  │
  o  e860deea161a2f77de56603b340ebbb4536308ae "e"
  │
  o  055a42cdd88768532f9cf79daa407fc8d138de9b "d"
  │
  o  177f92b773850b59254aa5e923436f921b55483b "c"
  │
  o  d2ae7f538514cd87c17547b0de4cea71fe1af9fb "b"
  │
  o  cb9a9f314b8b07ba71012fcdbc544b5a4d82ff5b "a"
  
  $ startediting 2 3 "(not changing anything)" # edit the 2nd of 3 changesets
  % start editing the history (not changing anything)
  | pick 055a42cdd887 d
  | edit e860deea161a e
  | pick 652413bf663e f
  0 files updated, 0 files merged, 2 files removed, 0 files unresolved
  Editing (e860deea161a), you may commit or record as needed now.
  (hg histedit --continue to resume)
  $ continueediting true "(leaving commit message unaltered)"
  % finalize changeset editing (leaving commit message unaltered)


check state of working copy
  $ hg id
  794fe033d0a0

  $ graphlog "log after history editing"
  % log after history editing
  @  794fe033d0a030f8df77c5de945fca35c9181c30 "f"
  │
  o  04d2fab980779f332dec458cc944f28de8b43435 "e"
  │
  o  055a42cdd88768532f9cf79daa407fc8d138de9b "d"
  │
  o  177f92b773850b59254aa5e923436f921b55483b "c"
  │
  o  d2ae7f538514cd87c17547b0de4cea71fe1af9fb "b"
  │
  o  cb9a9f314b8b07ba71012fcdbc544b5a4d82ff5b "a"
  

  $ cd ..

  $ initrepo r2 "test editing with no change, then abort"
  % test editing with no change, then abort
  -----------------------------------------
  $ cd r2
  $ graphlog "log before editing"
  % log before editing
  @  652413bf663ef2a641cab26574e46d5f5a64a55a "f"
  │
  o  e860deea161a2f77de56603b340ebbb4536308ae "e"
  │
  o  055a42cdd88768532f9cf79daa407fc8d138de9b "d"
  │
  o  177f92b773850b59254aa5e923436f921b55483b "c"
  │
  o  d2ae7f538514cd87c17547b0de4cea71fe1af9fb "b"
  │
  o  cb9a9f314b8b07ba71012fcdbc544b5a4d82ff5b "a"
  
  $ startediting 1,2 3 "(not changing anything)" # edit the 1st two of 3 changesets
  % start editing the history (not changing anything)
  | edit 055a42cdd887 d
  | edit e860deea161a e
  | pick 652413bf663e f
  0 files updated, 0 files merged, 3 files removed, 0 files unresolved
  Editing (055a42cdd887), you may commit or record as needed now.
  (hg histedit --continue to resume)
  $ continueediting true "(leaving commit message unaltered)"
  % finalize changeset editing (leaving commit message unaltered)
  Editing (e860deea161a), you may commit or record as needed now.
  (hg histedit --continue to resume)
  $ graphlog "log after first edit"
  % log after first edit
  @  e5ae3ca2f1ffdbd89ec41ebc273a231f7c3022f2 "d"
  │
  │ o  652413bf663ef2a641cab26574e46d5f5a64a55a "f"
  │ │
  │ o  e860deea161a2f77de56603b340ebbb4536308ae "e"
  │ │
  │ x  055a42cdd88768532f9cf79daa407fc8d138de9b "d"
  ├─╯
  o  177f92b773850b59254aa5e923436f921b55483b "c"
  │
  o  d2ae7f538514cd87c17547b0de4cea71fe1af9fb "b"
  │
  o  cb9a9f314b8b07ba71012fcdbc544b5a4d82ff5b "a"
  

abort editing session, after first forcibly updating away
  $ hg up 0
  abort: histedit in progress
  (use 'hg histedit --continue' to continue or
       'hg histedit --abort' to abort)
  [255]
  $ mv .hg/histedit-state .hg/histedit-state-ignore
  $ hg up 'desc(a)'
  0 files updated, 0 files merged, 3 files removed, 0 files unresolved
  $ mv .hg/histedit-state-ignore .hg/histedit-state
  $ hg sum
  parent: cb9a9f314b8b 
   a
  commit: 1 added, 1 unknown
  phases: 7 draft
  hist:   2 remaining (histedit --continue)

  $ hg histedit --abort 2>&1 | fixbundle

modified files should survive the abort when we've moved away already
  $ hg st
  A e
  ? edit.sh

  $ graphlog "log after abort"
  % log after abort
  o  652413bf663ef2a641cab26574e46d5f5a64a55a "f"
  │
  o  e860deea161a2f77de56603b340ebbb4536308ae "e"
  │
  o  055a42cdd88768532f9cf79daa407fc8d138de9b "d"
  │
  o  177f92b773850b59254aa5e923436f921b55483b "c"
  │
  o  d2ae7f538514cd87c17547b0de4cea71fe1af9fb "b"
  │
  @  cb9a9f314b8b07ba71012fcdbc544b5a4d82ff5b "a"
  
aborting and not changing files can skip mentioning updating (no) files
  $ hg up
  5 files updated, 0 files merged, 0 files removed, 0 files unresolved
  $ hg commit -m 'closebranch' --config ui.allowemptycommit=1
  $ startediting 1 1 "(not changing anything)" # edit the 3rd of 3 changesets
  % start editing the history (not changing anything)
  | edit 663c31f74acc closebranch
  Editing (663c31f74acc), you may commit or record as needed now.
  (hg histedit --continue to resume)
  $ hg histedit --abort

  $ cd ..
