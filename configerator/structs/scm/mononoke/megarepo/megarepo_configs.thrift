// @generated SignedSource<<fab2422ff24279f29b598bbacf254267>>
// DO NOT EDIT THIS FILE MANUALLY!
// This file is a mechanical copy of the version in the configerator repo. To
// modify it, edit the copy in the configerator repo instead and copy it over by
// running the following in your fbcode directory:
//
// configerator-thrift-updater scm/mononoke/megarepo/megarepo_configs.thrift

// (c) Facebook, Inc. and its affiliates. Confidential and proprietary.

namespace cpp2 facebook.scm.service
namespace py3 scm.service.thrift
namespace py scm.service.thrift.megarepo_configs
namespace php SourceControlMegarepoConfigStructs

// Megarepo service structs

typedef i64 RepoId
typedef string BookmarkName
typedef string Path
typedef string Prefix
typedef string SyncConfigVersion
typedef binary ChangesetId

/// Source revisions we are interested in
union SourceRevision {
    /// Source is pinned to a given changeset
    1: ChangesetId hash,
    /// Source is tracking a bookmark
    2: BookmarkName bookmark,
}

/// How to remap paths in a given source
struct SourceMappingRules {
    /// If no other rule matches, prepend this prefix
    /// to the source path when rewriting
    1: Prefix default_prefix,
    /// Mapping from link name to a target
    3: map<Path, Path> linkfiles,
    /// Paths for which default behavior is overridden
    /// - if a path maps to an empty list, anything
    ///   starting with it is skipped while rewriting
    ///   into a target repo
    /// - if a path maps to multiple items, many files
    ///   will be created in the target repo, with the
    ///   same contents as the original file
    4: map<Prefix, list<Prefix>> overrides,
} (rust.exhaustive)

/// Synchronization source
struct Source {
    /// A name to match sources across version bumps
    /// Has no meaning, except for book-keeping
    1: string source_name,
    /// Monooke repository id, where source is located
    2: RepoId repo_id,
    /// Name of the original (git) repo, from which this source comes
    3: string name,
    /// Source revisions, from where sync happens
    4: SourceRevision revision,
    /// Rules of commit sync
    5: SourceMappingRules mapping,
} (rust.exhaustive)

/// Synchronization target
struct Target {
    /// Mononoke repository id, where the target is located
    1: RepoId repo_id,
    /// Bookmark, which this target represents
    2: BookmarkName bookmark,
} (rust.exhaustive)

/// A single version of synchronization config for a target,
/// bundling together all of the corresponding sources
struct SyncTargetConfig {
    // A target to which this config can apply
    1: Target target,
    // All of the sources to sync from
    2: list<Source> sources
    // The version of this config
    3: SyncConfigVersion version
} (rust.exhaustive)
