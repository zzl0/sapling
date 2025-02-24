/**
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import clientToServerAPI from '../ClientToServerAPI';
import {codeReviewProviderJotai} from '../codeReview/CodeReviewInfo';
import {lazyAtom} from '../jotaiUtils';
import {useAtomValue} from 'jotai';
import {atomFamily} from 'jotai/utils';
import {cached} from 'shared/LRU';

import './RenderedMarkup.css';

const renderedMarkup = atomFamily((markup: string) => {
  // This is an atom to trigger re-render when the server returns.
  return lazyAtom(get => {
    const provider = get(codeReviewProviderJotai);
    if (provider?.enableMessageSyncing !== true) {
      return markup;
    }
    return renderMarkupToHTML(markup);
  }, markup);
});

let requestId = 0;

const renderMarkupToHTML = cached((markup: string): Promise<string> | string => {
  requestId += 1;
  const id = requestId;
  clientToServerAPI.postMessage({type: 'renderMarkup', markup, id});
  return new Promise(resolve => {
    clientToServerAPI
      .nextMessageMatching('renderedMarkup', message => message.id === id)
      .then(message => resolve(message.html));
  });
});

export function RenderMarkup({children}: {children: string}) {
  const renderedHtml = useAtomValue(renderedMarkup(children));
  // TODO: We could consider using DOM purify to sanitize this HTML,
  // though this html is coming directly from a trusted server.
  return renderedHtml != null ? (
    <div className="rendered-markup" dangerouslySetInnerHTML={{__html: renderedHtml}} />
  ) : (
    <div>{children}</div>
  );
}
