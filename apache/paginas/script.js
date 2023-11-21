document.getElementById('themeToggle').addEventListener('click', toggleTheme);

function toggleTheme() {
    const body = document.body;
    const currentTheme = body.classList.contains('dark-theme') ? 'dark' : 'light';

    body.classList.toggle('dark-theme');

    // Puedes ajustar el cambio de tema según tu preferencia, por ejemplo, cambiando colores y estilos específicos.
    if (currentTheme === 'light') {
        body.classList.remove('light-theme');
    } else {
        body.classList.add('light-theme');
    }
}
