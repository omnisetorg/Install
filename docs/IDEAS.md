# OmniSet v2.0 - Идеи и Архитектура

## Проблем с текущия подход

"Personalities" са ограничаващи:
- Потребителят е принуден да избере предефиниран пакет
- Няма гъвкавост - какво ако искаш fullstack БЕЗ Docker?
- Трудно за разширяване
- Не е интуитивно за нови потребители

---

## Нова Визия: Web-Based Module Selector

### Концепция

```
┌─────────────────────────────────────────────────────────────┐
│  🌐 GitHub Pages (omniset.github.io)                        │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  ☐ Development        ☐ Creative       ☐ Gaming    │    │
│  │    ☑ VS Code            ☐ DaVinci        ☐ Steam   │    │
│  │    ☑ Docker             ☐ GIMP           ☐ Discord │    │
│  │    ☐ VirtualBox         ☐ Inkscape                 │    │
│  │                                                     │    │
│  │  ☐ Browsers           ☐ CLI Tools                  │    │
│  │    ☑ Chrome             ☑ fzf                      │    │
│  │    ☐ Firefox            ☑ ripgrep                  │    │
│  │    ☐ Brave              ☑ eza                      │    │
│  │                                                     │    │
│  │  ═══════════════════════════════════════════════   │    │
│  │  Selected: 6 apps | ~850MB | Est. time: 8 min      │    │
│  │                                                     │    │
│  │  [Copy Command]  [Download Config]  [QR Code]      │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  Terminal                                                    │
│  $ curl -sL omniset.io/i | bash -s -- vscode,docker,chrome  │
│  # или                                                       │
│  $ omniset install --config ~/.omniset-selection.yaml       │
└─────────────────────────────────────────────────────────────┘
```

---

## Варианти за Свързване Web ↔ Script

### Вариант 1: URL-Encoded Selection (Най-просто)

**Как работи:**
1. Потребителят избира в уеб интерфейса
2. Сайтът генерира команда с избраните модули
3. Потребителят копира и изпълнява

```bash
# Генерирана команда
curl -sL https://omniset.io/install.sh | bash -s -- \
  --modules="vscode,docker,chrome,fzf,ripgrep"
```

**Плюсове:**
- Изключително просто
- Няма нужда от backend
- Работи офлайн след като имаш скрипта

**Минуси:**
- Дълга команда при много модули

---

### Вариант 2: Config File Download

**Как работи:**
1. Потребителят избира в уеб интерфейса
2. Сваля YAML конфигурационен файл
3. Изпълнява инсталатора с файла

```yaml
# ~/.omniset-config.yaml (генериран от уеб)
version: 1
generated: 2024-01-15T10:30:00Z

modules:
  development:
    - vscode
    - docker
  browsers:
    - chrome
  cli:
    - fzf
    - ripgrep
    - eza
    - zoxide

options:
  docker:
    install_compose: true
    install_desktop: false
  vscode:
    extensions:
      - ms-python.python
      - esbenp.prettier-vscode
```

```bash
# Изпълнение
curl -sL https://omniset.io/install.sh | bash -s -- --config ~/Downloads/omniset-config.yaml
```

**Плюсове:**
- По-четимо
- Може да се запази и преизползва
- Позволява детайлни опции

**Минуси:**
- Допълнителна стъпка (сваляне на файл)

---

### Вариант 3: Short Code System (Като Kahoot/Mentimeter)

**Как работи:**
1. Потребителят избира в уеб интерфейса
2. Сайтът генерира кратък код (напр. `ABC123`)
3. Кодът се съхранява в GitHub Gist или JSON file в repo
4. Скриптът чете конфигурацията по кода

```bash
# Потребителят получава код: DEV-2024-XK9
curl -sL https://omniset.io/i | bash -s -- DEV-2024-XK9
```

**Плюсове:**
- Много кратка команда
- Лесно за споделяне
- "Запази моята конфигурация"

**Минуси:**
- Изисква съхранение (GitHub Gist, JSON в repo)
- Зависи от интернет за четене на кода

---

### Вариант 4: Base64 Encoded Config (Хибрид)

**Как работи:**
1. Селекцията се кодира в base64
2. Кодът е част от URL/командата
3. Скриптът декодира и инсталира

```bash
# Уеб генерира:
curl -sL https://omniset.io/i | bash -s -- \
  --b64="eyJtb2R1bGVzIjpbInZzY29kZSIsImRvY2tlciJdfQ=="

# Декодирано: {"modules":["vscode","docker"]}
```

**Плюсове:**
- Всичко в една команда
- Няма нужда от external storage
- Може да е QR код

**Минуси:**
- По-дълга команда от short code
- Не е човешки четимо

---

### Вариант 5: QR Code (За мобилни/демонстрации)

**Как работи:**
1. Уеб интерфейсът генерира QR код
2. QR кодът съдържа пълната команда или short code
3. Сканираш с телефона, получаваш командата

**Use case:** Workshops, presentations, sharing setups

---

## Препоръчителен Подход: Комбинация

```
┌─────────────────────────────────────────────────────────┐
│                    Web Interface                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │  [Select Modules...]                            │    │
│  │                                                 │    │
│  │  Output Format:                                 │    │
│  │  ◉ Quick Command (URL params)                  │    │
│  │  ○ Config File (YAML download)                 │    │
│  │  ○ Share Code (for teams)                      │    │
│  │  ○ QR Code (for mobile)                        │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

---

## Web Interface Design

### Страници

1. **Home** - Бърз старт с популярни пресети
2. **Builder** - Пълен селектор на модули
3. **Presets** - Community споделени конфигурации
4. **Docs** - Документация за всеки модул

### Builder Interface

```
┌─────────────────────────────────────────────────────────────────┐
│  OmniSet Builder                                    [Dark Mode] │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Quick Start Presets:                                           │
│  [🚀 Web Developer] [🎨 Designer] [📊 Data Science] [🎮 Gamer] │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  🔧 DEVELOPMENT                        🌐 BROWSERS              │
│  ┌─────────────────────────────┐      ┌────────────────────┐   │
│  │ ☑ VS Code           ~200MB │      │ ☑ Chrome    ~150MB │   │
│  │   └─ Extensions:           │      │ ☐ Firefox   ~100MB │   │
│  │     ☑ Python               │      │ ☐ Brave     ~120MB │   │
│  │     ☑ Prettier             │      └────────────────────┘   │
│  │     ☐ ESLint               │                                │
│  │ ☑ Docker            ~500MB │      📧 COMMUNICATION          │
│  │   └─ ☑ Docker Compose      │      ┌────────────────────┐   │
│  │   └─ ☐ Docker Desktop      │      │ ☐ Discord   ~100MB │   │
│  │ ☐ VirtualBox        ~200MB │      │ ☐ Slack     ~150MB │   │
│  └─────────────────────────────┘      │ ☐ Zoom      ~200MB │   │
│                                        └────────────────────┘   │
│  💻 CLI TOOLS                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ ☑ Essential Pack (fzf, ripgrep, eza, fd, zoxide) ~50MB │   │
│  │ ☐ Extended Pack (bat, delta, dust, duf, gdu)     ~30MB │   │
│  │ ☐ System Monitor (btop, htop, glances)           ~20MB │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ─────────────────────────────────────────────────────────────  │
│                                                                 │
│  📊 Summary                                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Selected: 5 modules                                    │   │
│  │  Total Size: ~900 MB                                    │   │
│  │  Estimated Time: 8-12 minutes                           │   │
│  │                                                         │   │
│  │  Dependencies (auto-included):                          │   │
│  │  • curl, wget, git (base requirements)                  │   │
│  │  • apt-transport-https (for repositories)               │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  curl -sL omniset.io/i | bash -s vscode,docker,chrome  │   │
│  │                                          [📋 Copy]      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  [📥 Download Config] [🔗 Share Link] [📱 QR Code]             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Техническа Имплементация

### GitHub Pages Структура

```
docs/                          # GitHub Pages source
├── index.html                 # Landing page
├── builder/
│   └── index.html             # Module selector app
├── presets/
│   └── index.html             # Community presets
├── assets/
│   ├── css/
│   │   └── style.css
│   └── js/
│       ├── app.js             # Main application
│       ├── modules.js         # Module definitions
│       └── generator.js       # Command/config generator
├── api/
│   └── modules.json           # Module catalog (static JSON)
└── install.sh                 # Main installer (redirects to raw)
```

### Module Catalog (Static JSON)

```json
{
  "version": "2.0.0",
  "categories": [
    {
      "id": "development",
      "name": "Development",
      "icon": "🔧",
      "modules": [
        {
          "id": "vscode",
          "name": "VS Code",
          "description": "Popular code editor by Microsoft",
          "size_mb": 200,
          "arch": ["amd64", "arm64"],
          "tags": ["editor", "ide", "popular"],
          "options": [
            {
              "id": "extensions",
              "type": "multiselect",
              "label": "Extensions",
              "choices": [
                {"id": "python", "name": "Python"},
                {"id": "prettier", "name": "Prettier"},
                {"id": "eslint", "name": "ESLint"}
              ]
            }
          ],
          "dependencies": [],
          "conflicts": []
        },
        {
          "id": "docker",
          "name": "Docker",
          "description": "Container platform",
          "size_mb": 500,
          "arch": ["amd64", "arm64"],
          "tags": ["containers", "devops"],
          "options": [
            {
              "id": "compose",
              "type": "boolean",
              "label": "Docker Compose",
              "default": true
            },
            {
              "id": "desktop",
              "type": "boolean",
              "label": "Docker Desktop",
              "default": false
            }
          ]
        }
      ]
    }
  ]
}
```

### JavaScript App (Vue/React или Vanilla)

```javascript
// js/generator.js

class OmniSetGenerator {
  constructor(modules) {
    this.modules = modules;
    this.selected = new Map();
  }

  toggle(moduleId, options = {}) {
    if (this.selected.has(moduleId)) {
      this.selected.delete(moduleId);
    } else {
      this.selected.set(moduleId, options);
    }
    this.updateUI();
  }

  generateCommand() {
    const modules = Array.from(this.selected.keys()).join(',');
    return `curl -sL https://omniset.io/i | bash -s -- ${modules}`;
  }

  generateConfig() {
    const config = {
      version: 1,
      generated: new Date().toISOString(),
      modules: {}
    };

    for (const [id, options] of this.selected) {
      config.modules[id] = options;
    }

    return YAML.stringify(config);
  }

  generateShareCode() {
    const data = JSON.stringify(Array.from(this.selected.entries()));
    return btoa(data).replace(/=/g, '').substring(0, 12);
  }

  generateQRCode() {
    const command = this.generateCommand();
    return QRCode.toDataURL(command);
  }

  getTotalSize() {
    let total = 0;
    for (const id of this.selected.keys()) {
      const module = this.findModule(id);
      if (module) total += module.size_mb;
    }
    return total;
  }
}
```

---

## Installer Script Updates

### Нов Entry Point

```bash
#!/bin/bash
# install.sh - OmniSet v2 Installer

set -euo pipefail

OMNISET_VERSION="2.0.0"
OMNISET_REPO="https://raw.githubusercontent.com/user/omniset/main"

# Parse input - supports multiple formats
parse_input() {
    local input="$1"

    # Format 1: Comma-separated modules
    # vscode,docker,chrome
    if [[ "$input" =~ ^[a-z,-]+$ ]]; then
        echo "$input" | tr ',' '\n'
        return
    fi

    # Format 2: Base64 encoded config
    # --b64=eyJtb2R1bGVzIj...
    if [[ "$input" =~ ^--b64= ]]; then
        local b64="${input#--b64=}"
        echo "$b64" | base64 -d | jq -r '.modules[]'
        return
    fi

    # Format 3: Config file
    # --config=/path/to/config.yaml
    if [[ "$input" =~ ^--config= ]]; then
        local config_file="${input#--config=}"
        yq -r '.modules | keys[]' "$config_file"
        return
    fi

    # Format 4: Short code (fetch from remote)
    # ABC123
    if [[ "$input" =~ ^[A-Z0-9]{6,12}$ ]]; then
        curl -sL "${OMNISET_REPO}/presets/${input}.json" | jq -r '.modules[]'
        return
    fi
}

# Interactive mode if no arguments
interactive_mode() {
    echo "OmniSet Interactive Installer"
    echo ""
    echo "No modules specified. Options:"
    echo "1) Open web builder: https://omniset.io/builder"
    echo "2) Use a preset (minimalist, fullstack, etc.)"
    echo "3) Enter modules manually"
    echo ""
    read -p "Choice [1-3]: " choice

    case "$choice" in
        1)
            echo "Opening web builder..."
            xdg-open "https://omniset.io/builder" 2>/dev/null || \
            open "https://omniset.io/builder" 2>/dev/null || \
            echo "Please visit: https://omniset.io/builder"
            exit 0
            ;;
        2)
            echo "Available presets:"
            echo "  minimalist - Essential CLI tools only"
            echo "  fullstack  - Web development setup"
            echo "  creative   - Design and media tools"
            read -p "Preset: " preset
            MODULES=$(curl -sL "${OMNISET_REPO}/presets/${preset}.json" | jq -r '.modules[]')
            ;;
        3)
            echo "Enter modules (comma-separated):"
            echo "Example: vscode,docker,chrome,fzf"
            read -p "Modules: " input
            MODULES=$(echo "$input" | tr ',' '\n')
            ;;
    esac
}

main() {
    if [[ $# -eq 0 ]]; then
        interactive_mode
    else
        MODULES=$(parse_input "$1")
    fi

    echo "Modules to install:"
    echo "$MODULES" | while read -r mod; do
        echo "  • $mod"
    done

    read -p "Continue? [Y/n] " confirm
    [[ "$confirm" =~ ^[Nn] ]] && exit 0

    # Download and run installer
    for module in $MODULES; do
        echo "Installing $module..."
        curl -sL "${OMNISET_REPO}/modules/${module}/install.sh" | bash
    done
}

main "$@"
```

---

## Roadmap

### Phase 1: Core Refactor ✅
- [ ] Нова директорийна структура
- [ ] Module manifest система
- [ ] Base installer framework

### Phase 2: Web Interface
- [ ] GitHub Pages setup
- [ ] Module selector UI
- [ ] Command generator
- [ ] Config file generator

### Phase 3: Enhanced Features
- [ ] Short code sharing
- [ ] QR code generation
- [ ] Community presets
- [ ] User accounts (optional)

### Phase 4: Polish
- [ ] Documentation site
- [ ] Module search
- [ ] Compatibility checker
- [ ] Installation analytics (opt-in)

---

## Алтернативни Идеи

### TUI (Terminal UI) Selector

Вместо уеб, можем да направим интерактивен терминален интерфейс с `whiptail` или `dialog`:

```bash
┌──────────────────────────────────────────────────┐
│            OmniSet Module Selector               │
├──────────────────────────────────────────────────┤
│                                                  │
│  [X] vscode      VS Code Editor                  │
│  [X] docker      Container Platform              │
│  [ ] virtualbox  Virtual Machines                │
│  [X] chrome      Web Browser                     │
│  [ ] firefox     Web Browser                     │
│  [X] fzf         Fuzzy Finder                    │
│  [X] ripgrep     Fast Search                     │
│                                                  │
│         <OK>            <Cancel>                 │
└──────────────────────────────────────────────────┘
```

**Плюсове:** Работи без браузър, чист терминален опит
**Минуси:** По-ограничен UI, не е толкова красив

### Hybrid: Web + TUI

1. Уеб за браузване и избор
2. Генерира команда
3. Командата стартира TUI за потвърждение и опции

---

## Заключение

Най-добрият подход е **комбинация от**:
1. **Web Builder** (GitHub Pages) - за удобен избор
2. **URL-encoded команди** - за простота
3. **YAML config files** - за запазване и споделяне
4. **TUI fallback** - за терминал-only потребители

Това дава максимална гъвкавост без да усложнява основния flow.
