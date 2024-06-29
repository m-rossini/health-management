let configPromise = null;

export function loadConfig() {
    if (!configPromise) {
        configPromise = fetch('/config.json')
            .then(response => response.json())
            .then(data => {
                console.info('Login.Config loaded in promise:', JSON.stringify(data));
                return data})
            .catch(error => {
                console.error('Error loading config:', error);
                throw error;
            });
    }
    return configPromise;
}

document.getElementById('loginForm').addEventListener('submit', async (event) => {
    event.preventDefault();
    
    const config = await loadConfig();
    console.info(">>>Login.config: ", JSON.stringify(config));
    const urlLogin = config.urls['user-login'];
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;

    const response = await fetch(`${urlLogin}/login` , {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ email, password }),
        credentials: 'include'
    });

    if (response.ok) {
        console.info('Login successful! User:', email);
        sessionStorage.setItem('userMail', JSON.stringify(email));
        window.location.href = 'main.html';
    } else {
        alert('Login failed!');
    }
});
