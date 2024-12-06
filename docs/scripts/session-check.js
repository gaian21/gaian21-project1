// Check if user is logged in
function isLoggedIn() {
    try {
        const session = sessionStorage.getItem('user_session');
        return session !== null;
    } catch (error) {
        console.error('Session check error:', error);
        return false;
    }
}

// Redirect to appropriate page
function handleHomeNavigation(event) {
    if (isLoggedIn()) {
        event.preventDefault();
        window.location.href = 'loginmain.html';
    }
}

// Initialize home link handling
function initSessionCheck() {
    const homeLinks = document.querySelectorAll('a[href="index.html"], a[href="/"], .logo');
    homeLinks.forEach(link => {
        link.addEventListener('click', handleHomeNavigation);
    });
}

// Run on page load
document.addEventListener('DOMContentLoaded', initSessionCheck);