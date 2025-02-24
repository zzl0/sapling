/**
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import {repositoryInfoJotai} from '../../serverAPIState';
import {atom} from 'jotai';
import {atomFamily} from 'jotai/utils';

/**
 * Configured pull request domain to view associated pull requests, such as reviewstack.dev.
 */
export const pullRequestDomain = atom<string | undefined>(get => {
  const info = get(repositoryInfoJotai);
  return info?.type !== 'success' ? undefined : info.pullRequestDomain;
});

export const openerUrlForDiffUrl = atomFamily((url?: string) => {
  return atom(get => {
    if (!url) {
      return url;
    }
    const newDomain = get(pullRequestDomain);
    if (newDomain) {
      return url.replace(
        /^https:\/\/[^/]+/,
        newDomain.startsWith('https://') ? newDomain : `https://${newDomain}`,
      );
    }
    return url;
  });
});
