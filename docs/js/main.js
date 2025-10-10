// Main JavaScript for SLIPS documentation

// Smooth scroll for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Add scroll animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.style.opacity = '1';
            entry.target.style.transform = 'translateY(0)';
        }
    });
}, observerOptions);

// Observe elements with animation
document.addEventListener('DOMContentLoaded', () => {
    const animatedElements = document.querySelectorAll('.feature-card, .doc-nav, .doc-content');
    animatedElements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(20px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });

    // Syntax highlighting for code blocks
    highlightCode();

    // Copy button for code blocks
    addCopyButtons();
});

// Simple syntax highlighting
function highlightCode() {
    document.querySelectorAll('pre code').forEach(block => {
        const code = block.textContent;
        const highlighted = code
            // Swift keywords
            .replace(/\b(func|let|var|class|struct|enum|protocol|extension|import|return|if|else|guard|switch|case|for|while|in|mutating|public|private|internal|static|init|deinit|throws|try|catch|async|await)\b/g, '<span style="color: #ff79c6;">$1</span>')
            // CLIPS keywords
            .replace(/\b(defrule|deftemplate|deffacts|assert|retract|printout|bind|slot|multislot|defglobal|watch|unwatch|run|reset|clear)\b/g, '<span style="color: #8be9fd;">$1</span>')
            // Strings
            .replace(/"([^"\\]|\\.)*"/g, '<span style="color: #f1fa8c;">$&</span>')
            // Comments
            .replace(/\/\/.*$/gm, '<span style="color: #6272a4;">$&</span>')
            .replace(/\/\*[\s\S]*?\*\//g, '<span style="color: #6272a4;">$&</span>')
            // Numbers
            .replace(/\b(\d+\.?\d*)\b/g, '<span style="color: #bd93f9;">$1</span>')
            // Variables starting with ?
            .replace(/\?[\w-]+/g, '<span style="color: #50fa7b;">$&</span>');
        
        block.innerHTML = highlighted;
    });
}

// Add copy buttons to code blocks
function addCopyButtons() {
    document.querySelectorAll('pre').forEach(pre => {
        const button = document.createElement('button');
        button.textContent = 'Copy';
        button.className = 'copy-btn';
        button.style.cssText = `
            position: absolute;
            top: 0.5rem;
            right: 0.5rem;
            padding: 0.25rem 0.75rem;
            background: rgba(99, 102, 241, 0.2);
            border: 1px solid var(--primary);
            border-radius: 0.25rem;
            color: var(--primary-light);
            cursor: pointer;
            font-size: 0.8rem;
            transition: all 0.3s ease;
        `;
        
        pre.style.position = 'relative';
        pre.appendChild(button);

        button.addEventListener('click', async () => {
            const code = pre.querySelector('code').textContent;
            try {
                await navigator.clipboard.writeText(code);
                button.textContent = 'Copied!';
                button.style.background = 'rgba(16, 185, 129, 0.2)';
                button.style.borderColor = 'var(--success)';
                button.style.color = 'var(--success)';
                setTimeout(() => {
                    button.textContent = 'Copy';
                    button.style.background = 'rgba(99, 102, 241, 0.2)';
                    button.style.borderColor = 'var(--primary)';
                    button.style.color = 'var(--primary-light)';
                }, 2000);
            } catch (err) {
                console.error('Failed to copy:', err);
            }
        });

        button.addEventListener('mouseenter', () => {
            button.style.background = 'rgba(99, 102, 241, 0.4)';
        });

        button.addEventListener('mouseleave', () => {
            if (button.textContent === 'Copy') {
                button.style.background = 'rgba(99, 102, 241, 0.2)';
            }
        });
    });
}

// Language switcher functionality (for documentation pages)
function initLanguageSwitcher() {
    const langButtons = document.querySelectorAll('.lang-switch button');
    langButtons.forEach(button => {
        button.addEventListener('click', () => {
            const lang = button.dataset.lang;
            const currentPath = window.location.pathname;
            const newPath = currentPath.includes('/it/') 
                ? currentPath.replace('/it/', '/en/')
                : currentPath.replace('/en/', '/it/');
            window.location.pathname = newPath;
        });
    });
}

// Initialize on load
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initLanguageSwitcher);
} else {
    initLanguageSwitcher();
}

// Navbar scroll effect
let lastScroll = 0;
window.addEventListener('scroll', () => {
    const navbar = document.querySelector('.navbar');
    const currentScroll = window.pageYOffset;
    
    if (currentScroll > 100) {
        navbar.style.background = 'rgba(15, 23, 42, 0.95)';
        navbar.style.boxShadow = '0 4px 20px rgba(0, 0, 0, 0.3)';
    } else {
        navbar.style.background = 'rgba(15, 23, 42, 0.8)';
        navbar.style.boxShadow = 'none';
    }
    
    lastScroll = currentScroll;
});

