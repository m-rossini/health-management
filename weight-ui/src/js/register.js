import { getConfig } from "./datamanagement";

document.getElementById('registerForm').addEventListener('submit', async (event) => {
    event.preventDefault();

    const full_name = document.getElementById('full_name').value;
    const preferred_name = document.getElementById('preferred_name').value;
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    const date_of_birth = document.getElementById('date_of_birth').value;

    try {
        const config = getConfig();
        const urlLogin = config.urls['user-login'];

        const response = await fetch(`${urlLogin}/register`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ full_name, preferred_name, email, password, date_of_birth }),
            credentials: 'include'
        });

        if (response.ok) {
            alert('Registration successful! You can now login.');
            window.location.href = 'index.html';
        } else {
            alert('Registration failed!');
        }
    } catch (error) {
        alert('Registration failed!');
        console.error('Error registering user:', error);
    }
});
