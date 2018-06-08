#!/usr/bin/env python3
#
# Copyright (c) 2016-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree. An additional grant
# of patent rights can be found in the PATENTS file in the same directory.

from ..lib import hgrepo
from .lib.hg_extension_test_base import EdenHgTestCase, hg_test


@hg_test
class SparseTest(EdenHgTestCase):
    def populate_backing_repo(self, repo):
        repo.write_file("a_file.txt", "")
        repo.commit("first commit")

    def test_sparse(self):
        """Verify that we show a reasonable error if someone has managed
        to load the sparse extension, rather than an ugly stack trace"""

        for sub in [
            "clear",
            "cwd",
            "delete",
            "disableprofile",
            "enableprofile",
            "exclude",
            "explain",
            "files",
            "importrules",
            "include",
            "list",
            "refresh",
            "reset",
        ]:
            with self.assertRaises(hgrepo.HgError) as context:
                self.hg("--config", "extensions.fbsparse=", "sparse", sub)
            self.assertIn(
                "don't need sparse profiles",
                context.exception.stderr.decode("utf-8", errors="replace"),
            )
