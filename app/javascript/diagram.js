import cytoscape from 'cytoscape';

const initialize = () => {
  drawDiagram(document.getElementById('root'));
};

const drawDiagram = element => {
  const {servers, nodes} = JSON.parse(element.getAttribute('data-assets'));

  const graphNodes = [
    // XXX If a server doesnt have an associated node it currently appears
    // smaller/like a node, should probably make graph nodes always appear same
    // size regardless of (lack of) contents.
    ...servers.map(s => {
      return {
        data: {
          id: `server-${s.id}`,
          name: s.name,
        },
      };
    }),
    ...nodes.map(n => {
      return {
        data: {
          id: `node-${n.id}`,
          parent: `server-${n.server_id}`,
          name: n.name,
        },
      };
    }),
  ];

  cytoscape({
    container: element,

    boxSelectionEnabled: false,
    autounselectify: true,

    style: [
      {
        selector: 'node',
        css: {
          // So name (rather than id) displayed for nodes.
          content: 'data(name)',
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
      padding: 5,
    },
  });
};

document.addEventListener('turbolinks:load', initialize);
