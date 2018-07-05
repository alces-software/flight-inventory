import Flipping from 'flipping/dist/flipping.web';

import Elm from 'Main';

const initialize = () => {
  const elmApp = initializeApp();

  const handleViewportChange = sendAllPositions(elmApp);

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

  app.ports.animateSwitchLayout.subscribe(animateSwitchLayout);

  return app;
};

const sendAllPositions = elmApp => () => {
  [
    {idAttr: 'data-network-adapter-id', elmDataTag: 'networkAdapterPositions'},
    {idAttr: 'data-network-switch-id', elmDataTag: 'networkSwitchPositions'},
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

const animateSwitchLayout = () => {
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
    flipping.flip();
  });
};

export default initialize;
