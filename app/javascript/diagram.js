import cytoscape from 'cytoscape';

const initialize = () => {
  drawDiagram(document.getElementById('root'));
};

const drawDiagram = element => {
  const {chassis, servers, nodes} = JSON.parse(
    element.getAttribute('data-assets'),
  );

  const graphNodes = [
    // XXX If a parent (e.g. server) doesn't have an associated child (e.g.
    // node) it currently appears smaller/like a node, should probably make
    // graph nodes always appear same size regardless of (lack of) contents.
    // XXX Have this data come from JSON encoding in Rails rather than being
    // hard-coded here?
    ...chassis.map(c => {
      return {
        data: {
          id: `chassis-${c.id}`,
          name: c.name,
          type: 'Chassis',
          physicality: 'Physical',
        },
      };
    }),
    ...servers.map(s => {
      return {
        data: {
          id: `server-${s.id}`,
          parent: `chassis-${s.chassis_id}`,
          name: s.name,
          type: 'Server',
          // XXX Give this property a better name?
          physicality: 'Physical',
        },
      };
    }),
    ...nodes.map(n => {
      return {
        data: {
          id: `node-${n.id}`,
          parent: `server-${n.server_id}`,
          name: n.name,
          type: 'Node',
          physicality: 'Logical',
        },
      };
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
      name: 'grid',
      // XXX Slightly hacky way to make labels not overlap; come back and do
      // better.
      spacingFactor: 1.5,
    },
  });
};

document.addEventListener('turbolinks:load', initialize);
