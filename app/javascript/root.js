import ColorHash from 'color-hash';

const colorHash = new ColorHash({lightness: 0.4});

const run = () => {
  const groupElements = Array.from(document.getElementsByClassName('group'));

  groupElements.forEach(element => {
    // Deterministically get colour hash from group name.
    const groupName = element.getAttribute('data-group-name');
    const groupColor = colorHash.hex(groupName);

    // Colour group border.
    element.setAttribute('style', `border-color: ${groupColor};`);

    // Colour group title.
    const groupNameElement = element.getElementsByClassName('group-name')[0];
    groupNameElement.setAttribute('style', `color: ${groupColor};`);
  });
};

export default run;
