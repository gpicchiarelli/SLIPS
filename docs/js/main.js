// SLIPS Documentation JavaScript

document.addEventListener('DOMContentLoaded', () => {
    highlightCode();
    addCopyButtons();
});

// Smooth scroll
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({ behavior: 'smooth' });
        }
    });
});

// Syntax highlighting
function highlightCode() {
    document.querySelectorAll('pre code').forEach(block => {
        const code = block.textContent;
        const highlighted = code
            // Swift/CLIPS keywords
            .replace(/\b(func|let|var|class|struct|enum|import|return|if|else|guard|switch|for|while|mutating|public|private|static|defrule|deftemplate|deffacts|assert|retract|printout|bind|slot|watch|run|reset)\b/g, '<span style="color: #ff79c6;">$1</span>')
            // Strings
            .replace(/"([^"\\]|\\.)*"/g, '<span style="color: #f1fa8c;">$&</span>')
            // Comments
            .replace(/\/\/.*$/gm, '<span style="color: #6272a4;">$&</span>')
            // Numbers
            .replace(/\b(\d+\.?\d*)\b/g, '<span style="color: #bd93f9;">$1</span>')
            // Variables
            .replace(/\?[\w-]+/g, '<span style="color: #50fa7b;">$&</span>');
        
        block.innerHTML = highlighted;
    });
}

// Copy buttons
function addCopyButtons() {
    document.querySelectorAll('pre').forEach(pre => {
        const button = document.createElement('button');
        button.textContent = 'Copy';
        button.className = 'copy-btn';
        pre.style.position = 'relative';
        pre.appendChild(button);

        button.addEventListener('click', async () => {
            const code = pre.querySelector('code').textContent;
            try {
                await navigator.clipboard.writeText(code);
                button.textContent = 'Copied!';
                setTimeout(() => {
                    button.textContent = 'Copy';
                }, 2000);
            } catch (err) {
                console.error('Failed to copy:', err);
            }
        });
    });
}

// Navbar scroll effect
window.addEventListener('scroll', () => {
    const navbar = document.querySelector('.navbar');
    if (window.pageYOffset > 50) {
        navbar.style.background = 'rgba(15, 23, 42, 0.98)';
    } else {
        navbar.style.background = 'rgba(15, 23, 42, 0.95)';
    }
});
