// Check login status and handle navigation
function isLoggedIn() {
    return sessionStorage.getItem('user_session') !== null;
}

function handleNavigation(event) {
    event.preventDefault();
    window.location.href = isLoggedIn() ? 'loginmain.html' : 'index.html';
}

// Add click handler to all Greek Syllector links
document.addEventListener('DOMContentLoaded', () => {
    const logoLinks = document.querySelectorAll('a.logo');
    logoLinks.forEach(link => {
        link.addEventListener('click', handleNavigation);
    });
});