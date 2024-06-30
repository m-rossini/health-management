import { deleteEntry } from "./healthdatamanagement";
import { updateAnalysisButtonState } from "./handleAnalysisButton";

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

export function populateEntryForm(entry) {
    if (!entry) {
        return;
    }
    document.getElementById('date_time').value = entry.date_time;
    document.getElementById('weight').value = entry.weight;
    document.getElementById('height').value = entry.height;
    document.getElementById('bp_systolic').value = entry.bp_systolic;
    document.getElementById('bp_diastolic').value = entry.bp_diastolic;
    document.getElementById('heart_rate').value = entry.heart_rate;
}
export function populateTable(entries) {
    const tableBody = document.getElementById('entriesTable').querySelector('tbody');
    tableBody.innerHTML = ''; // Clear existing content (optional)
    entries.forEach((entry, index) => {
        const className = index % 2 === 0 ? 'even-row' : 'odd-row';
        const row = document.createElement('tr');
        row.classList.add(className);

        appendAllFields(row, entry);

        const deleteButton = createDeleteButton(entry, index);
        row.appendChild(deleteButton);

        tableBody.appendChild(row);

        row.addEventListener('click', (event) => {
            const cells = event.currentTarget.cells;
            const field = {
                'date_time': cells[0].textContent.trim(),
                'weight': cells[1].textContent.trim(),
                'height': cells[2].textContent.trim(),
                'bp_systolic': cells[3].textContent.trim(),
                'bp_diastolic': cells[4].textContent.trim(),
                'heart_rate': cells[5].textContent.trim()
            }
            populateEntryForm(field);
        })
    });
}

function appendAllFields(row, entry) {
    const dateCell = document.createElement('td');
    dateCell.textContent = entry.date_time;
    dateCell.classList.add('left-align');
    row.appendChild(dateCell);

    const weightCell = document.createElement('td');
    weightCell.textContent = entry.weight;
    weightCell.classList.add('right-align');
    row.appendChild(weightCell);
    
    const heightCell = document.createElement('td');
    heightCell.textContent = entry.height;
    heightCell.classList.add('right-align');
    row.appendChild(heightCell);

    const bpSystolicCell = document.createElement('td');
    bpSystolicCell.textContent = entry.bp_systolic;
    bpSystolicCell.classList.add('right-align');
    row.appendChild(bpSystolicCell);

    const bpDiastolicCell = document.createElement('td');
    bpDiastolicCell.textContent = entry.bp_diastolic;
    bpDiastolicCell.classList.add('right-align');
    row.appendChild(bpDiastolicCell);

    const heartRateCell = document.createElement('td');
    heartRateCell.textContent = entry.heart_rate;
    heartRateCell.classList.add('right-align');
    row.appendChild(heartRateCell);
}
function createDeleteButton(entry, index) {
    const deleteButton = document.createElement('button');
    deleteButton.classList.add('delete-btn');
    deleteButton.dataset.id = entry.id;
    deleteButton.dataset.index = index;
    deleteButton.textContent = 'Delete';
    return deleteButton;
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
                alert('Error deleting entry:', error);
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
            updateAnalysisButtonState(table);
        });
    });
}