import Elm from 'Main';

const networkAdapterIdAttr = 'data-network-adapter-id';

const initialize = () => {
  const elmApp = initializeApp();
  sendPositionsData(elmApp);
};

const initializeApp = () => {
  const target = document.getElementById('root');
  const assetsData = JSON.parse(target.getAttribute('data-assets'));
  return Elm.Main.embed(target, assetsData);
};

const sendPositionsData = elmApp => {
  // XXX Do this a less hacky way than just with `setTimeout`, so both occurs
  // sooner (or later if initial render very slow) and re-occurs if page
  // reflows.
  window.setTimeout(() => {
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
  }, 1000);
};

export default initialize;
