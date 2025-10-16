# SLIPS Documentation Site

This directory contains the bilingual documentation website for SLIPS (Swift Language Implementation of Production Systems).

## 🌐 Live Site

Visit the documentation at: [https://gpicchiarelli.github.io/SLIPS/](https://gpicchiarelli.github.io/SLIPS/)

## 📁 Structure

```
docs/
├── index.html          # Landing page with language selector
├── en/                 # English documentation
│   └── index.html
├── it/                 # Italian documentation
│   └── index.html
├── css/
│   └── style.css       # Modern, responsive styling
├── js/
│   └── main.js         # Interactive features
└── README.md           # This file
```

## 🚀 Features

- **Bilingual Support**: Complete documentation in English and Italian
- **Modern Design**: Beautiful gradient UI with animated backgrounds
- **Responsive**: Mobile-first design that works on all devices
- **Code Highlighting**: Syntax highlighting for Swift and CLIPS code
- **Copy Buttons**: One-click code copying from examples
- **Smooth Animations**: Fade-in effects and smooth scrolling
- **Dark Theme**: Eye-friendly dark color scheme

## 🛠️ Local Development

To test the site locally:

```bash
# Simple HTTP server with Python
cd docs
python3 -m http.server 8000

# Or with Node.js
npx http-server -p 8000

# Then open http://localhost:8000
```

## 📝 Updating Documentation

1. Edit the appropriate HTML file:
   - Landing page: `index.html`
   - English docs: `en/index.html`
   - Italian docs: `it/index.html`

2. Modify styles in `css/style.css`

3. Update interactive features in `js/main.js`

4. Commit and push to GitHub - GitHub Pages will automatically deploy

## 🎨 Customization

### Colors

Edit CSS variables in `css/style.css`:

```css
:root {
    --primary: #6366f1;
    --secondary: #ec4899;
    --bg-dark: #0f172a;
    /* ... */
}
```

### Fonts

Currently using:
- **Body**: Inter (Google Fonts)
- **Code**: JetBrains Mono (Google Fonts)

## 📄 License

Same as SLIPS project - see main repository LICENSE file.

## 🤝 Contributing

Contributions to improve the documentation are welcome! Please:

1. Keep the bilingual aspect (update both EN and IT versions)
2. Maintain the existing design language
3. Test responsiveness on mobile devices
4. Ensure code examples are accurate and tested

---

Built with ❤️ for the SLIPS project

