/**
 * OmniSet Module Icons
 * Uses Simple Icons (simpleicons.org) - stored locally
 * License: CC0 1.0 (Public Domain) - see assets/icons/CREDITS.md
 */

// Modules that have icons available
const ModuleIcons = [
    'docker', 'nodejs', 'python', 'go', 'rust', 'php', 'vscode',
    'chrome', 'firefox', 'postgresql', 'mysql', 'redis', 'mongodb',
    'discord', 'slack', 'telegram', 'zoom', 'signal', 'thunderbird',
    'gimp', 'inkscape', 'blender', 'obs', 'kdenlive', 'audacity',
    'steam', 'lutris', 'vlc', 'virtualbox', 'git', 'essentials', 'modern-cli'
];

// Get icon URL for a module
function getIconUrl(moduleId) {
    if (ModuleIcons.includes(moduleId)) {
        return `assets/icons/${moduleId}.svg`;
    }
    return null;
}

// Check if module has an icon
function hasIcon(moduleId) {
    return ModuleIcons.includes(moduleId);
}

// Create icon element
function createIconElement(moduleId, size = 24) {
    const url = getIconUrl(moduleId);

    if (url) {
        const img = document.createElement('img');
        img.src = url;
        img.alt = moduleId;
        img.width = size;
        img.height = size;
        img.className = 'module-icon';
        img.loading = 'lazy';
        return img;
    }

    // Fallback to emoji
    const span = document.createElement('span');
    span.className = 'module-icon-fallback';
    span.textContent = getFallbackEmoji(moduleId);
    return span;
}

// Fallback emojis for modules without icons
function getFallbackEmoji(moduleId) {
    const emojis = {
        docker: '🐳',
        nodejs: '💚',
        python: '🐍',
        go: '🔵',
        rust: '🦀',
        php: '🐘',
        vscode: '💻',
        chrome: '🌐',
        firefox: '🦊',
        postgresql: '🐘',
        mysql: '🐬',
        redis: '🔴',
        mongodb: '🍃',
        discord: '💬',
        slack: '💼',
        telegram: '✈️',
        zoom: '📹',
        signal: '🔒',
        thunderbird: '📧',
        gimp: '🎨',
        inkscape: '✒️',
        blender: '🎬',
        obs: '📺',
        kdenlive: '🎞️',
        audacity: '🎵',
        steam: '🎮',
        lutris: '🎯',
        vlc: '▶️',
        virtualbox: '📦',
        git: '🔀',
        essentials: '⚡',
        'modern-cli': '✨'
    };
    return emojis[moduleId] || '📦';
}

// Export
window.ModuleIcons = ModuleIcons;
window.getIconUrl = getIconUrl;
window.hasIcon = hasIcon;
window.createIconElement = createIconElement;
window.getFallbackEmoji = getFallbackEmoji;
