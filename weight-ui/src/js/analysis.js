document.addEventListener('DOMContentLoaded', function () {
    const analysisData = JSON.parse(localStorage.getItem('analysisData'));
    console.log(">>>analysisData", analysisData)
    const resultsDiv = document.getElementById('analysisResults');
    console.info(">>>resultsDiv", resultsDiv)
    if (analysisData && analysisData.length > 0) {
        // Perform your analysis here
        // This is a simple example - you'd replace this with your actual analysis
        const averageWeight = analysisData.reduce((sum, entry) => sum + parseFloat(entry.weight), 0) / analysisData.length;

        resultsDiv.innerHTML = `
            <h2>Analysis Results</h2>
            <p>Number of entries: ${analysisData.length}</p>
            <p>Average weight: ${averageWeight.toFixed(2)} kg</p>
            <!-- Add more analysis results here -->
        `;
    } else {
        resultsDiv.innerHTML = '<p>No data available for analysis.</p>';
    }
});