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
  return Elm.Main.embed(target, assetsData);
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

export default initialize;
