/**
 * OmniSet Module Selector
 * Web interface for selecting and generating installation commands
 */

class OmniSetSelector {
    constructor() {
        this.modules = [];
        this.categories = [];
        this.presets = [];
        this.selected = new Map(); // moduleId -> options
        this.baseUrl = 'https://omniset.io';

        this.init();
    }

    async init() {
        // Load modules data
        await this.loadModules();

        // Render UI
        this.renderPresets();
        this.renderCategories();

        // Setup event listeners
        this.setupEventListeners();

        // Check URL for pre-selected modules
        this.loadFromUrl();

        // Initialize theme
        this.initTheme();
    }

    async loadModules() {
        try {
            const response = await fetch('api/modules.json');
            const data = await response.json();

            this.categories = data.categories;
            this.presets = data.presets || [];

            // Flatten modules for easy lookup
            this.modules = [];
            for (const cat of this.categories) {
                for (const mod of cat.modules) {
                    mod.categoryId = cat.id;
                    this.modules.push(mod);
                }
            }
        } catch (error) {
            console.error('Failed to load modules:', error);
            this.showError('Failed to load modules. Please refresh the page.');
        }
    }

    // Escape HTML to prevent XSS
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.textContent;
    }

    // ═══════════════════════════════════════════════════════════
    // Rendering with DOM API (safe from XSS)
    // ═══════════════════════════════════════════════════════════

    renderPresets() {
        const container = document.getElementById('presets-container');
        if (!container) return;

        const icons = {
            'code': '💻',
            'server': '🖥️',
            'palette': '🎨',
            'box': '📦',
            'default': '🚀'
        };

        // Clear container
        container.replaceChildren();

        this.presets.forEach(preset => {
            const card = document.createElement('div');
            card.className = 'preset-card';
            card.dataset.preset = preset.id;

            const icon = document.createElement('div');
            icon.className = 'preset-icon';
            icon.textContent = icons[preset.icon] || icons.default;

            const name = document.createElement('div');
            name.className = 'preset-name';
            name.textContent = preset.name;

            const desc = document.createElement('div');
            desc.className = 'preset-desc';
            desc.textContent = preset.description;

            card.appendChild(icon);
            card.appendChild(name);
            card.appendChild(desc);

            card.addEventListener('click', () => this.selectPreset(preset.id));
            container.appendChild(card);
        });
    }

    renderCategories() {
        const container = document.getElementById('categories-container');
        if (!container) return;

        const icons = {
            'cli': '💻',
            'development': '🔧',
            'browsers': '🌐',
            'communication': '💬',
            'creative': '🎨',
            'media': '▶️',
            'databases': '🗄️',
            'gaming': '🎮',
            'system': '⚙️'
        };

        // Clear container
        container.replaceChildren();

        this.categories.forEach(category => {
            const catEl = document.createElement('div');
            catEl.className = 'category';
            catEl.dataset.category = category.id;

            // Header
            const header = document.createElement('div');
            header.className = 'category-header';

            const catIcon = document.createElement('span');
            catIcon.className = 'category-icon';
            catIcon.textContent = icons[category.id] || '📁';

            const catName = document.createElement('span');
            catName.className = 'category-name';
            catName.textContent = category.name;

            const catCount = document.createElement('span');
            catCount.className = 'category-count';
            catCount.textContent = category.modules.length;

            const catToggle = document.createElement('span');
            catToggle.className = 'category-toggle';
            catToggle.textContent = '▼';

            header.appendChild(catIcon);
            header.appendChild(catName);
            header.appendChild(catCount);
            header.appendChild(catToggle);
            header.addEventListener('click', () => this.toggleCategory(category.id));

            // Modules grid
            const grid = document.createElement('div');
            grid.className = 'modules-grid';

            category.modules.forEach(mod => {
                grid.appendChild(this.createModuleCard(mod));
            });

            catEl.appendChild(header);
            catEl.appendChild(grid);
            container.appendChild(catEl);
        });
    }

    createModuleCard(module) {
        const isSelected = this.selected.has(module.id);
        const isDisabled = this.isModuleDisabled(module);

        const card = document.createElement('div');
        card.className = `module-card ${isSelected ? 'selected' : ''} ${isDisabled ? 'disabled' : ''}`;
        card.dataset.module = module.id;

        // Checkbox
        const checkbox = document.createElement('div');
        checkbox.className = 'module-checkbox';
        checkbox.textContent = isSelected ? '✓' : '';

        // Info container
        const info = document.createElement('div');
        info.className = 'module-info';

        const name = document.createElement('div');
        name.className = 'module-name';
        name.textContent = module.name;

        const desc = document.createElement('div');
        desc.className = 'module-desc';
        desc.textContent = module.description;

        const meta = document.createElement('div');
        meta.className = 'module-meta';

        module.arch.forEach(arch => {
            const tag = document.createElement('span');
            tag.className = 'module-tag';
            tag.textContent = arch;
            meta.appendChild(tag);
        });

        const size = document.createElement('span');
        size.className = 'module-size';
        size.textContent = `${module.size_mb}MB`;
        meta.appendChild(size);

        info.appendChild(name);
        info.appendChild(desc);
        info.appendChild(meta);

        card.appendChild(checkbox);
        card.appendChild(info);

        card.addEventListener('click', () => this.toggleModule(module.id));

        return card;
    }

    updateModuleCard(moduleId) {
        const card = document.querySelector(`[data-module="${moduleId}"]`);
        if (!card) return;

        const isSelected = this.selected.has(moduleId);
        card.className = `module-card ${isSelected ? 'selected' : ''}`;
        card.querySelector('.module-checkbox').textContent = isSelected ? '✓' : '';
    }

    // ═══════════════════════════════════════════════════════════
    // Selection Logic
    // ═══════════════════════════════════════════════════════════

    toggleModule(moduleId) {
        const module = this.modules.find(m => m.id === moduleId);
        if (!module || this.isModuleDisabled(module)) return;

        if (this.selected.has(moduleId)) {
            this.selected.delete(moduleId);
        } else {
            this.selected.set(moduleId, {});

            // Auto-select dependencies
            if (module.requires) {
                for (const dep of module.requires) {
                    if (!this.selected.has(dep)) {
                        this.selected.set(dep, {});
                        this.updateModuleCard(dep);
                    }
                }
            }
        }

        this.updateModuleCard(moduleId);
        this.updateSummary();
        this.updateUrl();
    }

    selectPreset(presetId) {
        const preset = this.presets.find(p => p.id === presetId);
        if (!preset) return;

        // Clear current selection
        this.selected.clear();

        // Select all modules in preset
        for (const moduleId of preset.modules) {
            this.selected.set(moduleId, {});
        }

        // Update UI
        this.renderCategories();
        this.updateSummary();
        this.updateUrl();

        // Highlight selected preset
        document.querySelectorAll('.preset-card').forEach(card => {
            card.classList.toggle('selected', card.dataset.preset === presetId);
        });
    }

    clearSelection() {
        this.selected.clear();
        this.renderCategories();
        this.updateSummary();
        this.updateUrl();

        document.querySelectorAll('.preset-card').forEach(card => {
            card.classList.remove('selected');
        });
    }

    isModuleDisabled(module) {
        // Check architecture compatibility (simplified - would need actual detection)
        return false;
    }

    // ═══════════════════════════════════════════════════════════
    // Summary & Output
    // ═══════════════════════════════════════════════════════════

    updateSummary() {
        const count = this.selected.size;
        const size = this.calculateTotalSize();

        document.getElementById('selected-count').textContent = count;
        document.getElementById('total-size').textContent = size;

        document.getElementById('clear-btn').disabled = count === 0;
        document.getElementById('generate-btn').disabled = count === 0;
    }

    calculateTotalSize() {
        let total = 0;
        for (const moduleId of this.selected.keys()) {
            const module = this.modules.find(m => m.id === moduleId);
            if (module) {
                total += module.size_mb;
            }
        }
        return total;
    }

    generateCommand() {
        const modules = Array.from(this.selected.keys()).join(',');
        return `curl -sL ${this.baseUrl}/i | bash -s -- ${modules}`;
    }

    generateConfig() {
        const config = {
            version: 1,
            generated: new Date().toISOString(),
            modules: Array.from(this.selected.keys())
        };

        // Convert to YAML-like format (simple)
        let yaml = `# OmniSet Configuration\n`;
        yaml += `# Generated: ${config.generated}\n\n`;
        yaml += `version: ${config.version}\n\n`;
        yaml += `modules:\n`;
        for (const moduleId of config.modules) {
            yaml += `  - ${moduleId}\n`;
        }

        return yaml;
    }

    generateShareUrl() {
        const modules = Array.from(this.selected.keys()).join(',');
        return `${this.baseUrl}/builder?m=${encodeURIComponent(modules)}`;
    }

    showOutputModal() {
        const modal = document.getElementById('command-modal');

        // Update content using textContent (safe)
        document.getElementById('output-command').textContent = this.generateCommand();
        document.getElementById('output-config').textContent = this.generateConfig();
        document.getElementById('output-share-url').textContent = this.generateShareUrl();

        // Show modal
        modal.classList.add('open');
    }

    // ═══════════════════════════════════════════════════════════
    // Event Handlers
    // ═══════════════════════════════════════════════════════════

    setupEventListeners() {
        // Generate button
        document.getElementById('generate-btn').addEventListener('click', () => {
            this.showOutputModal();
        });

        // Clear button
        document.getElementById('clear-btn').addEventListener('click', () => {
            this.clearSelection();
        });

        // Search
        document.getElementById('search-input').addEventListener('input', (e) => {
            this.filterModules(e.target.value);
        });

        // Tab switching
        document.querySelectorAll('.output-tabs .tab').forEach(tab => {
            tab.addEventListener('click', (e) => {
                const tabId = e.target.dataset.tab;
                this.switchTab(tabId);
            });
        });

        // Theme toggle
        document.getElementById('theme-toggle').addEventListener('click', () => {
            this.toggleTheme();
        });
    }

    toggleCategory(categoryId) {
        const category = document.querySelector(`[data-category="${categoryId}"]`);
        if (category) {
            category.classList.toggle('collapsed');
        }
    }

    filterModules(query) {
        const normalizedQuery = query.toLowerCase().trim();

        document.querySelectorAll('.module-card').forEach(card => {
            const moduleId = card.dataset.module;
            const module = this.modules.find(m => m.id === moduleId);

            if (!module) return;

            const matches =
                module.name.toLowerCase().includes(normalizedQuery) ||
                module.description.toLowerCase().includes(normalizedQuery) ||
                (module.tags && module.tags.some(t => t.includes(normalizedQuery)));

            card.style.display = matches ? '' : 'none';
        });

        // Hide empty categories
        document.querySelectorAll('.category').forEach(cat => {
            const visibleModules = cat.querySelectorAll('.module-card:not([style*="display: none"])');
            cat.style.display = visibleModules.length > 0 ? '' : 'none';
        });
    }

    switchTab(tabId) {
        document.querySelectorAll('.output-tabs .tab').forEach(tab => {
            tab.classList.toggle('active', tab.dataset.tab === tabId);
        });

        document.querySelectorAll('.tab-content').forEach(content => {
            content.classList.toggle('active', content.id === `tab-${tabId}`);
        });
    }

    // ═══════════════════════════════════════════════════════════
    // URL State Management
    // ═══════════════════════════════════════════════════════════

    updateUrl() {
        const modules = Array.from(this.selected.keys());
        const url = new URL(window.location.href);

        if (modules.length > 0) {
            url.searchParams.set('m', modules.join(','));
        } else {
            url.searchParams.delete('m');
        }

        window.history.replaceState({}, '', url);
    }

    loadFromUrl() {
        const url = new URL(window.location.href);
        const modulesParam = url.searchParams.get('m');

        if (modulesParam) {
            const modules = modulesParam.split(',');
            for (const moduleId of modules) {
                if (this.modules.find(m => m.id === moduleId)) {
                    this.selected.set(moduleId, {});
                }
            }
            this.renderCategories();
            this.updateSummary();
        }
    }

    // ═══════════════════════════════════════════════════════════
    // Theme
    // ═══════════════════════════════════════════════════════════

    initTheme() {
        const savedTheme = localStorage.getItem('omniset-theme');
        const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;

        if (savedTheme === 'dark' || (!savedTheme && prefersDark)) {
            document.documentElement.setAttribute('data-theme', 'dark');
            document.getElementById('theme-toggle').textContent = '☀️';
        }
    }

    toggleTheme() {
        const isDark = document.documentElement.getAttribute('data-theme') === 'dark';

        if (isDark) {
            document.documentElement.removeAttribute('data-theme');
            document.getElementById('theme-toggle').textContent = '🌙';
            localStorage.setItem('omniset-theme', 'light');
        } else {
            document.documentElement.setAttribute('data-theme', 'dark');
            document.getElementById('theme-toggle').textContent = '☀️';
            localStorage.setItem('omniset-theme', 'dark');
        }
    }

    // ═══════════════════════════════════════════════════════════
    // Utilities
    // ═══════════════════════════════════════════════════════════

    showError(message) {
        // Simple error display
        alert(message);
    }
}

// ═══════════════════════════════════════════════════════════════
// Global Functions (for onclick handlers)
// ═══════════════════════════════════════════════════════════════

let app;

document.addEventListener('DOMContentLoaded', () => {
    app = new OmniSetSelector();
});

function closeModal() {
    document.getElementById('command-modal').classList.remove('open');
}

function copyCommand() {
    const command = document.getElementById('output-command').textContent;
    navigator.clipboard.writeText(command).then(() => {
        showCopyFeedback(event.target);
    });
}

function copyShareUrl() {
    const url = document.getElementById('output-share-url').textContent;
    navigator.clipboard.writeText(url).then(() => {
        showCopyFeedback(event.target);
    });
}

function downloadConfig() {
    const config = app.generateConfig();
    const blob = new Blob([config], { type: 'text/yaml' });
    const url = URL.createObjectURL(blob);

    const a = document.createElement('a');
    a.href = url;
    a.download = 'omniset-config.yaml';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}

function showCopyFeedback(btn) {
    const original = btn.textContent;
    btn.textContent = '✓ Copied!';
    setTimeout(() => {
        btn.textContent = original;
    }, 2000);
}
