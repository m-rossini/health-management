import { formatDateTime, extractFormData, populateTable, addEventToEntries, populateEntryForm } from './datamanagement.js';
import { fetchUserData } from './usermanagement.js';
import { extractAndConvertEntries } from './healthdatamanagement.js';
import { setAnalysisButtonListener, updateAnalysisButtonState } from './handleAnalysisButton.js';
import { getBMIWithCategory } from './datamanagement.js';

import DataTable from 'datatables.net-dt';
import 'datatables.net-colreorder-dt';
import 'datatables.net-responsive-dt';

let configPromise = null;
let config = undefined

export function loadConfig() {
    if (!configPromise) {
        configPromise = fetch('/config.json')
            .then(response => response.json())
            .then(data => {
                console.info('Main.Config loaded in promise:', JSON.stringify(data));
                return data
            })
            .catch(error => {
                console.error('Error loading config:', error);
                throw error;
            });
    }
    return configPromise;
}

function updateLogCountMessage(logEntryCount) {
    const countMsg = document.getElementById('logCountMessage');
    countMsg.textContent = `You have ${logEntryCount} entries in your log.`;
}

document.addEventListener('DOMContentLoaded', async () => {
    flatpickr("#date_time", {
        enableTime: true,
        dateFormat: "Y-m-dTH:i",
        defaultDate: new Date(),
        time_24hr: true
    });

    try {
        config = await loadConfig();
        const userMail = JSON.parse(sessionStorage.getItem('userMail'));
        const urlUserData = `${config.urls['user-login']}/user_data?user_id=${userMail}`;
        fetchUserData(urlUserData)
            .then((userData) => {
                if (userData) {
                    sessionStorage.setItem('userData', JSON.stringify(userData));
                    document.getElementById('userName').textContent = userData.preferred_name;

                    const formattedDateTime = formatDateTime(new Date());
                    document.getElementById('date_time').value = formattedDateTime;

                    const baseWeightUrl = config.urls['weight-api'];
                    const entriesArray = extractAndConvertEntries(`${baseWeightUrl}/get_entries?user_id=${userData.user_id}`);

                    entriesArray.then((entries) => {
                        updateLogCountMessage(entries.length);
                        return entries;
                    }).then((entries) => {
                        entries.map((entry) => {
                            const bmi = getBMIWithCategory(parseFloat(entry.weight), parseFloat(entry.height));
                            entry.bmi = bmi.bmi
                        })
                        return entries;
                    }).then((entries) => {
                        populateTable(entries);
                        return entries;
                    }).then((entries) => {
                        populateEntryForm(entries[entries.length - 1]);
                        return entries;
                    }).then((entries) => {
                        const deleteBaseUrl = `${baseWeightUrl}/delete_entry/${userData.user_id}`
                        addEventToEntries(deleteBaseUrl)
                        return entries;
                    }).then((entries) => {
                        prepareAnalysisArea(entries);
                        return entries;
                    })
                } else {
                    throw new Error('User data not fetched successfully');
                }
            })
            .catch((error) => {
                console.error("main.js>>> Error fetching user data: ", error);
                throw new Error('User data not fetched successfully');
            });
    } catch (error) {
        alert(`main.js>>>Error fetching user data: ${error.message}`);
        console.error('main.js>>>Error when creating entries page', error);
        try {
            const urlLogout = config.urls['user-logout'];
            await fetch(`${urlLogout}/logout`, {
                method: 'GET',
                credentials: 'include'
            });
        } catch (e) {
            console.warn('Failed to logout!', e);
        }
        window.location.href = 'index.html';
    }

});

function prepareAnalysisArea(entries) {
    let table = new DataTable('#entriesTable', {
        'paging': false,
        'searching': false,
        'ordering': true,
        'info': false,
        'colReorder': true,
        'responsive': true,
        // 'data': entries,
        'columns': [
            { data: 'date_time' },
            { data: 'weight' },
            { data: 'height' },
            { data: 'bmi' },
            { data: 'bp_systolic' },
            { data: 'bp_diastolic' },
            { data: 'heart_rate' },
        ]
    });

    updateAnalysisButtonState();
    setAnalysisButtonListener(table);
}

document.getElementById('entryForm').addEventListener('submit', async (event) => {
    event.preventDefault();

    const { date_time, weight, height, bp_systolic, bp_diastolic, heart_rate } = extractFormData();
    const userData = JSON.parse(sessionStorage.getItem('userData'));
    const user_id = userData.user_id;
    const baseWeightUrl = config.urls['weight-api'];
    try {
        const response = await fetch(`${baseWeightUrl}/add_entry`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ user_id, date_time, weight, height, bp_systolic, bp_diastolic, heart_rate }),
            credentials: 'include'
        });

        if (!response.ok) {
            throw new Error('Failed to add entry!');
        }

        location.reload();
    } catch (error) {
        alert(error.message);
    }
    const table = document.getElementById('entriesTable');
    updateAnalysisButtonState(table);
});

