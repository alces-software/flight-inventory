import cytoscape from 'cytoscape';
import cola from 'cytoscape-cola';

cytoscape.use(cola);

const initialize = () => {
  drawDiagram(document.getElementById('root'));
};

const drawDiagram = element => {
  const assetsData = JSON.parse(element.getAttribute('data-assets'));
  const {chassis, servers, nodes, networkAdapters} = assetsData;

  const graphId = (type, id) => `${type}-${id}`;

  // XXX If a parent (e.g. server) doesn't have an associated child (e.g.
  // node) it currently appears smaller/like a node, should probably make graph
  // nodes always appear same size regardless of (lack of) contents.
  // XXX Have this data come from JSON encoding in Rails rather than being
  // hard-coded here?
  const assetsToGraphNodes = (
    assets,
    type,
    {parentType = null, physicality = 'Physical'} = {},
  ) =>
    assets.map(asset => {
      let parentAttrs = {};
      if (parentType) {
        const parentDatabaseId = asset[`${parentType}_id`];
        const parentGraphId = graphId(parentType, parentDatabaseId);
        parentAttrs = {
          parent: parentGraphId,
        };
      }

      return {
        data: {
          id: graphId(type, asset.id),
          name: asset.name,
          type: type,
          // XXX Give this property a better name?
          physicality: physicality,
          ...parentAttrs,
        },
      };
    });

  const graphNodes = [
    ...assetsToGraphNodes(chassis, 'chassis'),
    ...assetsToGraphNodes(servers, 'server', {parentType: 'chassis'}),
    ...assetsToGraphNodes(networkAdapters, 'network_adapter', {
      parentType: 'server',
    }),
    ...assetsToGraphNodes(nodes, 'node', {
      parentType: 'server',
      physicality: 'Logical',
    }),
  ];

  const graphElementToLabel = element => {
    const data = element._private.data;
    return `${data.name} [${data.physicality} ${data.type}]`;
  };

  cytoscape({
    container: element,

    boxSelectionEnabled: false,
    autounselectify: true,

    style: [
      {
        selector: 'node',
        css: {
          content: graphElementToLabel,
          'text-valign': 'center',
          'text-halign': 'center',
          'text-wrap': 'wrap',
          'text-max-width': '200px',
        },
      },
      {
        selector: '$node > node',
        css: {
          'padding-top': '10px',
          'padding-left': '10px',
          'padding-bottom': '10px',
          'padding-right': '10px',
          'text-valign': 'top',
          'text-halign': 'center',
          'background-color': '#bbb',
        },
      },
      {
        selector: 'edge',
        css: {
          'target-arrow-shape': 'triangle',
        },
      },
      {
        selector: ':selected',
        css: {
          'background-color': 'black',
          'line-color': 'black',
          'target-arrow-color': 'black',
          'source-arrow-color': 'black',
        },
      },
    ],

    elements: {
      nodes: graphNodes,
      edges: [],
    },

    layout: {
      name: 'cola',
      animate: false,
      nodeDimensionsIncludeLabels: true,
      nodeSpacing: _node => 30,
    },
  });
};

document.addEventListener('turbolinks:load', initialize);
