export async function fetchUserData(urlUserData) {
    if (!urlUserData) {
        throw new Error('usermanagement.js>>>Missing url for user data');
    }
    try {
        const response = await fetch(urlUserData, {
            method: 'GET',
            credentials: 'include'
        });

        if (!response.ok) {
            throw new Error(`Failed to load user data! ${response.status} ${response.statusText}`);
        }
        return await response.json();
    } catch (error) {
        const errorMessage = `usermanagement.Error fetching user data: ${error.message}`;
        console.error(errorMessage);
        throw new Error(errorMessage);
    }
}

