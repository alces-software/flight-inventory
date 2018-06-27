import Elm from 'Main';

const networkAdapterIdAttr = 'data-network-adapter-id';

const initialize = () => {
  const elmApp = initializeApp();

  const handleViewportChange = sendPositionsData(elmApp);

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
  return Elm.Main.embed(target, assetsData);
};

const sendPositionsData = elmApp => () => {
  const adapterElements = Array.from(
    document.querySelectorAll(`[${networkAdapterIdAttr}]`),
  );

  const adaptersWithBoundingRects = adapterElements.map(element => {
    const elementAssetId = +element.getAttribute(networkAdapterIdAttr);
    const boundingRect = element.getBoundingClientRect();

    return [elementAssetId, boundingRect];
  });

  elmApp.ports.jsToElm.send([
    'networkAdapterPositions',
    adaptersWithBoundingRects,
  ]);
};

export default initialize;
