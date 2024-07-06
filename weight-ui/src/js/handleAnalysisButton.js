export function setAnalysisButtonListener(table) {
    const analysisButton = document.getElementById('analysisButton');
    const tableData = table.data().toArray();
    localStorage.setItem('analysisData', JSON.stringify(tableData));
    
    analysisButton.addEventListener('click', function() {
        window.open('analysis.html', '_blank');
    });
}

export function updateAnalysisButtonState() {
    const analysisButton = document.getElementById('analysisButton');
    const table = document.getElementById('entriesTable');
    if (!table) {
        analysisButton.enabled = false;
    } else {
        const rowCount = table.tBodies[0].rows.length;
        analysisButton.disabled = rowCount === 0;
    }
}