// Initialize variables
let map;

// Handle Set Location button click
document.addEventListener('DOMContentLoaded', function () {
    document.getElementById('set-location-btn').addEventListener('click', handleSetLocation);
});

async function handleSetLocation() {
    const city = document.getElementById('city-input').value.trim();
    if (!city) {
        alert('Please enter a city name.');
        return;
    }

    try {
        // 1. Geocode city
        const geocodeUrl = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(city)}`;
        const response = await fetch(geocodeUrl);
        const data = await response.json();

        if (data.length === 0) {
            alert('City not found. Please try again.');
            return;
        }

        const lat = parseFloat(data[0].lat);
        const lon = parseFloat(data[0].lon);

        // 2. Initialize or reset map
        if (map) {
            map.remove();
        }
        map = L.map('map').setView([lat, lon], 13);

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap contributors',
        }).addTo(map);

        // 3. Fetch nearby pharmacies using Overpass API
        const overpassQuery = `
            [out:json];
            node["amenity"="pharmacy"](around:5000, ${lat}, ${lon});
            out body;
        `;

        const pharmacyResponse = await fetch('https://overpass-api.de/api/interpreter', {
            method: 'POST',
            body: overpassQuery
        });

        const pharmacyData = await pharmacyResponse.json();

        if (!pharmacyData.elements.length) {
            alert('No pharmacies found near this city.');
            return;
        }

        const markers = [];

        pharmacyData.elements.forEach(el => {
            const marker = L.marker([el.lat, el.lon])
                .addTo(map)
                .bindPopup(`<b>${el.tags.name || 'Pharmacy'}</b>`);
            markers.push(marker);
        });

        const group = new L.featureGroup(markers);

        setTimeout(() => {
            map.invalidateSize();
            map.fitBounds(group.getBounds().pad(0.2));
        }, 200);

    } catch (error) {
        console.error('Error:', error);
        alert('Something went wrong. Please try again.');
    }
}
