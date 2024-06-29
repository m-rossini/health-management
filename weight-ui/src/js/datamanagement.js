import { deleteEntry } from "./healthdatamanagement";

export function formatDateTime(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');

    return `${year}-${month}-${day}T${hours}:${minutes}`;
}

export function extractFormData() {
    const date_time = document.getElementById('date_time').value;
    const weight = document.getElementById('weight').value;
    const height = document.getElementById('height').value;
    const bp_systolic = document.getElementById('bp_systolic').value;
    const bp_diastolic = document.getElementById('bp_diastolic').value;
    const heart_rate = document.getElementById('heart_rate').value;
    return { date_time, weight, height, bp_systolic, bp_diastolic, heart_rate };
}

export function populateTable(entries) {
    const tableBody = document.getElementById('entriesTable').querySelector('tbody');
    tableBody.innerHTML = entries.map((entry, index) => {
        const className = index % 2 === 0 ? 'even-row' : 'odd-row';
        return `
            <tr class="${className}">
                <td>${entry.date_time}</td>
                <td>${entry.weight}</td>
                <td>${entry.height}</td>
                <td>${entry.bp_systolic}</td>
                <td>${entry.bp_diastolic}</td>
                <td>${entry.heart_rate}</td>
                <td><button class="delete-btn" data-id="${entry.id}" data-index="${index}">Delete</button></td>
            </tr>
        `;
    }).join('');
}

export function addEventToEntries(deleteBaseUrl) {
    if (!deleteBaseUrl) {
        throw new Error('deleteBaseUrl is required');
    }
    const deleteButtons = document.querySelectorAll('.delete-btn');

    deleteButtons.forEach(button => {
        button.addEventListener('click', async function () {
            const entryId = this.getAttribute('data-id');
            if (!entryId) {
                throw new Error('data-id attribute is missing');
            }

            try {
                const deleteUrl = `${deleteBaseUrl}/${entryId}`;
                await deleteEntry(deleteUrl);
            } catch (error) {
                alert ('Error deleting entry:', error);
                console.error('Error deleting entry:', error);
                return;
            }

            const table = document.getElementById('entriesTable');
            if (!table) {
                throw new Error('entriesTable element is missing');
            }

            const tableRowsArray = Array.from(table.rows).slice(1);
            const theIndex = this.getAttribute('data-index');
            const rowToDelete = tableRowsArray.find(row => {
                const deleteButton = row.querySelector('.delete-btn');
                return deleteButton && deleteButton.dataset.index === theIndex;
            });

            if (rowToDelete) {
                rowToDelete.remove();
            }
        });
    });
}
