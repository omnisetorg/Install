# Contributing to OmniSet

## Getting Started

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Development Environment

```bash
git clone https://github.com/omnisetorg/install.git
cd install
./setup.sh # Use minimalist personality for development
```

## Project Structure

```
Project/
├── install/            # Installation scripts for individual applications
├── uninstall/          # Uninstallation scripts
└── docs/               # Documentation files
```

## Script Guidelines

1. Every installation script must:
   - Accept architecture as first parameter
   - Handle errors gracefully
   - Include cleanup on failure

2. Naming conventions:
   - Scripts: lowercase with hyphens
   - Functions: snake_case

## Documentation

1. Update README.md for new features
2. Document dependencies
3. Include example usage

## Code Review Process

1. Tests must pass - if any
2. Approvals required
3. No merge conflicts
4. Follows style guide

## Pull Request Template

```markdown
## Description
[Feature/Fix description]

## Type of change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update

## Testing
- [ ] Tested on Ubuntu
- [ ] Tested on Debian
- [ ] Tested on Raspberry Pi OS

## Checklist
- [ ] Updated documentation
- [ ] Added tests
- [ ] Follows style guide
```

## License

By contributing, you agree that your contributions will be licensed under the project's license.
