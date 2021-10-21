// @generated SignedSource<<d0d8d5fa4f895da70029f7de3aa5bc68>>
// DO NOT EDIT THIS FILE MANUALLY!
// This file is a mechanical copy of the version in the configerator repo. To
// modify it, edit the copy in the configerator repo instead and copy it over by
// running the following in your fbcode directory:
//
// configerator-thrift-updater scm/mononoke/pushredirect/enable.thrift

namespace rust mononoke.pushredirect.enable
namespace py configerator.pushredirect.enable

typedef i64 RepoId

struct PushRedirectEnableState {
  // Should we enable push redirect on infinitepush (draft) pushes?
  1: bool draft_push;
  // Should we enable push redirect on public pushes (push, pushrebase, bookmark moves)?
  2: bool public_push;
} (rust.exhaustive)

struct MononokePushRedirectEnable {
  // Map from repo to push redirection state
  1: map<RepoId, PushRedirectEnableState> per_repo;
} (rust.exhaustive)
