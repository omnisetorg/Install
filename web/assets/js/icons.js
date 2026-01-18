/**
 * OmniSet Module Icons
 * Uses Simple Icons (simpleicons.org) - stored locally
 * License: CC0 1.0 (Public Domain) - see assets/icons/CREDITS.md
 */

// Modules that have icons available
const ModuleIcons = [
    // CLI & Terminals
    'essentials', 'modern-cli', 'lazygit', 'alacritty', 'kitty', 'wezterm', 'ghostty',
    // Editors
    'vscode', 'cursor', 'zed', 'sublime', 'neovim', 'helix',
    // Browsers
    'chrome', 'firefox', 'brave',
    // Development
    'docker', 'nodejs', 'python', 'go', 'rust', 'php', 'java', 'dotnet',
    // Dev Tools
    'postman', 'dbeaver', 'insomnia',
    // DevOps
    'kubernetes', 'helm', 'terraform', 'ansible', 'tailscale', 'wireguard',
    // Databases
    'postgresql', 'mysql', 'mariadb', 'redis', 'valkey', 'mongodb', 'sqlite',
    // Communication
    'discord', 'slack', 'telegram', 'zoom', 'signal', 'thunderbird',
    // Productivity
    'libreoffice', 'obsidian', 'notion', 'bitwarden',
    // Creative
    'gimp', 'inkscape', 'figma', 'blender', 'obs', 'kdenlive', 'audacity',
    // Media
    'vlc', 'spotify',
    // Gaming
    'steam', 'lutris',
    // System
    'virtualbox', 'syncthing', 'qbittorrent',
    // Misc
    'git', 'tmux'
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
        // CLI
        essentials: '⚡',
        'modern-cli': '✨',
        lazygit: '🔀',
        // Terminals
        alacritty: '💻',
        kitty: '🐱',
        wezterm: '💻',
        ghostty: '👻',
        // Editors
        vscode: '💻',
        cursor: '🤖',
        zed: '⚡',
        sublime: '📝',
        neovim: '📗',
        helix: '🌀',
        // Browsers
        chrome: '🌐',
        firefox: '🦊',
        brave: '🦁',
        // Development
        docker: '🐳',
        nodejs: '💚',
        python: '🐍',
        go: '🔵',
        rust: '🦀',
        php: '🐘',
        java: '☕',
        dotnet: '🔷',
        // Dev Tools
        postman: '📮',
        dbeaver: '🦫',
        insomnia: '💜',
        // DevOps
        kubernetes: '☸️',
        helm: '⎈',
        terraform: '🏗️',
        ansible: '🔧',
        tailscale: '🔗',
        wireguard: '🔒',
        // Databases
        postgresql: '🐘',
        mysql: '🐬',
        mariadb: '🔱',
        redis: '🔴',
        valkey: '🔑',
        mongodb: '🍃',
        sqlite: '📦',
        // Communication
        discord: '💬',
        slack: '💼',
        telegram: '✈️',
        zoom: '📹',
        signal: '🔒',
        thunderbird: '📧',
        // Productivity
        libreoffice: '📄',
        obsidian: '💎',
        notion: '📓',
        bitwarden: '🔐',
        // Creative
        gimp: '🎨',
        inkscape: '✒️',
        figma: '🎨',
        blender: '🎬',
        obs: '📺',
        kdenlive: '🎞️',
        audacity: '🎵',
        // Media
        vlc: '▶️',
        spotify: '🎵',
        // Gaming
        steam: '🎮',
        lutris: '🎯',
        // System
        virtualbox: '📦',
        syncthing: '🔄',
        qbittorrent: '⬇️',
        // Misc
        git: '🔀',
        tmux: '📟'
    };
    return emojis[moduleId] || '📦';
}

// Export
window.ModuleIcons = ModuleIcons;
window.getIconUrl = getIconUrl;
window.hasIcon = hasIcon;
window.createIconElement = createIconElement;
window.getFallbackEmoji = getFallbackEmoji;
