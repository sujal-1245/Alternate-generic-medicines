// Theme toggle
const themeToggle = document.getElementById('theme-toggle');
themeToggle.addEventListener('click', () => {
    const htmlTag = document.documentElement;
    htmlTag.setAttribute('data-theme', htmlTag.getAttribute('data-theme') === 'light' ? 'dark' : 'light');
});

// Search functionality
const searchBtn = document.querySelector('.search-btn');
const searchInput = document.querySelector('.search-input');
const resultsSection = document.getElementById('results-section');  // Updated ID
const cardsWrapper = document.getElementById('cards-wrapper');

searchBtn.addEventListener('click', async () => {
    const medicineName = searchInput.value.trim();
    if (!medicineName) {
        alert('Please enter a medicine name.');
        return;
    }

    try {
        const response = await fetch('/search', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ medicine: medicineName }) // 👈 Match Flask
        });

        const result = await response.json();

        if (result.status === 'success') {
            displayResults(result.data);
        } else {
            alert('Medicine not found.');
        }
    } catch (error) {
        console.error('Error searching medicine:', error);
    }
});
function displayResults(medicines) {
    if (medicines.length > 0) {
        // Clear previous cards
        cardsWrapper.innerHTML = '';

        // Sort medicines by price to make sure the expensive one is first
        medicines.sort((a, b) => parseFloat(b['Price (₹)']) - parseFloat(a['Price (₹)']));

        // Add the brand medicine first (most expensive)
        const brandMedicine = medicines[0];
        const brandCard = document.createElement('div');
        brandCard.classList.add('medicine-card');
        brandCard.innerHTML = `
            <h3>💊 Brand Medicine</h3>
            <p><strong>Medicine:</strong> ${brandMedicine['Medicine Name'] || 'N/A'}</p>
            <p><strong>Manufacturer:</strong> ${brandMedicine['Manufacturer'] || 'N/A'}</p>
            <p><strong>Type:</strong> ${brandMedicine['Type'] || 'N/A'}</p>
            <p><strong>Pack Size:</strong> ${brandMedicine['Pack Size'] || 'N/A'}</p>
            <p><strong>Price (₹):</strong> ${brandMedicine['Price (₹)'] || 'N/A'}</p>
            ${brandMedicine['Symptoms'] ? `<p><strong>Symptoms:</strong> ${brandMedicine['Symptoms']}</p>` : ''}
        `;
        cardsWrapper.appendChild(brandCard);

        // Now add low-cost generics
        let genericAlternatives = medicines.slice(1); // Exclude the brand medicine

        // Filter: Only cheaper ones
        genericAlternatives = genericAlternatives.filter(medicine => parseFloat(medicine['Price (₹)']) < parseFloat(brandMedicine['Price (₹)']));

        // ✨ Select up to 7 generics
        const numberOfGenericsToShow = 7;
        const selectedGenerics = genericAlternatives.slice(0, numberOfGenericsToShow);

        if (selectedGenerics.length === 0) {
            alert('No cheaper alternatives found, showing brand medicine only.');
        }

        selectedGenerics.forEach((medicine) => {
            const card = document.createElement('div');
            card.classList.add('medicine-card');
            card.innerHTML = `
                <h3>✅ Generic Alternative</h3>
                <p><strong>Medicine:</strong> ${medicine['Medicine Name'] || 'N/A'}</p>
                <p><strong>Manufacturer:</strong> ${medicine['Manufacturer'] || 'N/A'}</p>
                <p><strong>Type:</strong> ${medicine['Type'] || 'N/A'}</p>
                <p><strong>Pack Size:</strong> ${medicine['Pack Size'] || 'N/A'}</p>
                <p><strong>Price (₹):</strong> ${medicine['Price (₹)'] || 'N/A'}</p>
                ${medicine['Symptoms'] ? `<p><strong>Symptoms:</strong> ${medicine['Symptoms']}</p>` : ''}
            `;
            cardsWrapper.appendChild(card);
        });

        resultsSection.style.display = 'block';
        window.scrollTo({ top: resultsSection.offsetTop, behavior: 'smooth' });
    } else {
        alert('No medicines found.');
    }
}

// Toggle the menu visibility when hamburger is clicked
function toggleMenu() {
    const navbar = document.querySelector('.navbar');
    navbar.classList.toggle('active');
  }
  