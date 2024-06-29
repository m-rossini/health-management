export async function fetchEntries(entriesUrl) {
    const entriesResponse = await fetch(entriesUrl, {
        method: 'GET',
        credentials: 'include'
    });

    if (!entriesResponse.ok) {
        console.error('Failed to load entries!', entriesResponse);
        throw new Error('Failed to load entries!');
    }
    return await entriesResponse.json();
}

export function convertEntries(entries) {
    try {
        console.log(">>> Entries: ", entries);
        return JSON.parse(entries); // Assuming data is string-encoded JSON
    } catch (error) {
        console.error('Error parsing response body:', error);
        return [];
    }
}

export async function extractAndConvertEntries(entriesUrl) {
    console.info("healthdatamanagement.js>>> extractAndConvert entriesUrl: ", entriesUrl);
    const results = fetchEntries(entriesUrl)
    .then((response) => {
        return response.entries
    })
    .then((entries) => {
        return (Array.isArray(entries)) ? entries : convertEntries(entries)
    })
    .catch((error) => {
        console.error('healtgdatamanagement.js>>>Error extracting and convertig entries:', error);
    });
    return results;
}

export async function deleteEntry(deleteUrl) {
    if (!deleteUrl) {
        console.error('Delete URL is null or undefined');
        return;
    }
    try {
        const response = await fetch(deleteUrl, {
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json'
            },
            credentials: 'include'
        });
        if (!response.ok) {
            const msg = `Failed to delete URL ${deleteUrl}! ${response.status} ${response.statusText}`;
            console.error(msg);
            throw new Error(msg);
        }
        console.info("healthdatamanagement.js>>> deleteEntry response: ", response);
        return response
    } catch (error) {
        console.error('Error:', error);
    }
}
