(function () {
  const form = document.getElementById('form');
  const input = document.getElementById('input');
  const items = document.getElementById('items');
  let state = [];

  function render() {
    items.innerHTML = '';
    state.forEach(function (item) {
      const row = document.createElement('li');
      row.textContent = item;
      items.appendChild(row);
    });
  }

  async function save() {
    await AppRuntime.storage.set('items', state);
    render();
  }

  form.addEventListener('submit', async function (event) {
    event.preventDefault();
    state.push(input.value.trim());
    input.value = '';
    await save();
  });

  AppRuntime.storage.get('items').then(function (value) {
    state = Array.isArray(value) ? value : [];
    render();
  });
})();
