import debounce from 'debounce';
import Flipping from 'flipping/dist/flipping.web';

import Elm from 'Main';

const initialize = () => {
  const elmApp = initializeApp();

  let handleViewportChange = sendAllPositions(elmApp);
  if (process.env.NODE_ENV === 'development') {
    // In development, debounce sending element positions with short wait when
    // viewport changes, to avoid spamming Elm app with many new position
    // messages in quick succession when e.g. user scrolls, causing degraded
    // performance. In production this seems not quite as bad, and so we still
    // want things to continually update rather than debounce - opinions may
    // change on this however, and/or we should investigate improving
    // performance generally so we don't need to do this at all.
    handleViewportChange = debounce(handleViewportChange, 50);
  }

  // Slightly arbitrary tiny wait, after which the app should (hopefully) have
  // initially rendered, before we send the initial positions of elements to
  // the app.
  // XXX Possibly better way to do this, I can imagine this could be too short
  // in some situations, but longer would be more noticeable always.
  const initialRenderWait = 50;
  window.setTimeout(handleViewportChange, initialRenderWait);

  ['scroll', 'resize'].forEach(eventName => {
    window.addEventListener(eventName, handleViewportChange);
  });
};

const initializeApp = () => {
  const target = document.getElementById('root');
  const assetsData = JSON.parse(target.getAttribute('data-assets'));
  const app = Elm.Main.embed(target, assetsData);

  app.ports.animateSwitchLayout.subscribe(animateSwitchLayout(app));

  return app;
};

const sendAllPositions = elmApp => () => {
  [
    {idAttr: 'data-network-adapter-id', elmDataTag: 'networkAdapterPositions'},
    {idAttr: 'data-network-switch-id', elmDataTag: 'networkSwitchPositions'},
    {idAttr: 'data-node-id', elmDataTag: 'nodePositions'},
    {idAttr: 'data-oob-id', elmDataTag: 'oobPositions'},
  ].forEach(args => sendPositionsForElements({...args, elmApp: elmApp}));
};

const sendPositionsForElements = ({idAttr, elmDataTag, elmApp}) => {
  const elements = Array.from(document.querySelectorAll(`[${idAttr}]`));

  const elementIdsWithBoundingRects = elements.map(element => {
    const elementAssetId = +element.getAttribute(idAttr);
    const boundingRect = element.getBoundingClientRect();

    return [elementAssetId, boundingRect];
  });

  elmApp.ports.jsToElm.send([elmDataTag, elementIdsWithBoundingRects]);
};

const animateSwitchLayout = elmApp => () => {
  // This function gets run after Elm's `update` but before the `view`, when
  // Elm sends the `Cmd` we are subscribed to through a port.
  const flipping = new Flipping({
    duration: 1000,
  });

  // Read the current layout, i.e. the start positions for the animation.
  flipping.read();

  // Request animation frame, effectively passing control back to Elm to render
  // the view, and then perform the animation from the recorded start positions
  // to the new rendered positions. Elm doesn't care and won't be affected by
  // us animating elements in this way, as their final positions will be the
  // ones Elm would have rendered directly without animation.
  requestAnimationFrame(() => {
    // Send the new positions of elements so Elm has these immediately after
    // the layout has changed (rather than requiring the viewport to otherwise
    // change before these will be sent, e.g. waiting for the user to scroll).
    // XXX There's a slight jump of the network diagram lines here as we render
    // them twice in quick succession with the old and then new positions,
    // would be nice to eliminate this.
    sendAllPositions(elmApp)();

    flipping.flip();
  });
};

export default initialize;
