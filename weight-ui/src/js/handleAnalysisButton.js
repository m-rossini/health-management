export function setAnalysisButtonListener(table) {
    const analysisButton = document.getElementById('analysisButton');
    console.info("Creating the button handler")
    analysisButton.addEventListener('click', function() {
        // Get table data
        const tableData = table.data().toArray();
        console.info(">>>processing button cliclk", tableData);
        // Store data in localStorage (or you could use sessionStorage)
        localStorage.setItem('analysisData', JSON.stringify(tableData));

        // Open new window/tab with analysis page
        window.open('analysis.html', '_blank');
    });
}

export function updateAnalysisButtonState(table) {
    const analysisButton = document.getElementById('analysisButton');
    console.info(">>>table", table )
    if (!table) {
        analysisButton.enabled = false;
    } else {
        analysisButton.disabled = table.rows().count() === 0;
    }
}