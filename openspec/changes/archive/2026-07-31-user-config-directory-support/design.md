## Context

Brigit uses `ghbranchprotection.json` to define branch protection rules. When installed via Nix, this file is placed in the read-only Nix store. The current implementation hardcodes the config location to `$SCRIPT_DIR/ghbranchprotection.json`, which prevents users from customizing their branch protection rules.

The XDG Base Directory specification recommends using `~/.config/` for user-specific configuration files. This is the standard on Linux systems and provides a predictable location for users to customize application behavior.

## Goals / Non-Goals

**Goals:**
- Support user-specific config in `~/.config/brigit/ghbranchprotection.json`
- Check user config first, fall back to system default
- Follow XDG Base Directory specification
- Document default config settings and location
- Provide clear instructions for customization
- Maintain backward compatibility

**Non-Goals:**
- Environment variable for config path (keep it simple)
- Multiple config file formats (JSON only)
- Auto-migration of existing configs (manual copy is fine)
- Config validation at load time (keep existing behavior)

## Decisions

### Decision 1: Config file search order

**Options:**
- **Option A**: User config only (`~/.config/brigit/`) - fail if not found
- **Option B**: User config first, fall back to system default
- **Option C**: Environment variable to specify location

**Choice**: Option B (user first, system fallback)

**Rationale**:
- Works out of the box with system default
- Users can override when needed
- No breaking changes to existing installations
- Simple mental model: "my config if I have one, otherwise default"

**Implementation**:
```bash
if [ -f "$HOME/.config/brigit/ghbranchprotection.json" ]; then
    CONFIG_FILE="$HOME/.config/brigit/ghbranchprotection.json"
else
    CONFIG_FILE="$SCRIPT_DIR/ghbranchprotection.json"
fi
```

### Decision 2: Documentation location

**Options:**
- **Option A**: Add config section to README.md
- **Option B**: Create separate CONFIG.md file
- **Option C**: Add to existing documentation sections

**Choice**: Option A (add to README.md)

**Rationale**:
- Config customization is common task, should be visible
- Keeps documentation centralized
- README already has configuration section
- Easier to discover than separate file

### Decision 3: Example config handling

**Options:**
- **Option A**: Users manually copy from system location
- **Option B**: Provide `brigit init-config` command
- **Option C**: Ship example file separately

**Choice**: Option A (manual copy)

**Rationale**:
- Simpler implementation - no new command needed
- Users explicitly choose to customize
- Clear documentation makes it easy
- Follows standard Unix pattern
- One-time operation doesn't warrant dedicated command

## Risks / Trade-offs

**Risk**: Users might not know about user config option
- **Mitigation**: Clear documentation in README.md with examples
- **Mitigation**: Document in help text where applicable

**Risk**: Two config files might cause confusion
- **Mitigation**: Clear precedence order (user > system)
- **Mitigation**: Document which file is being used

**Trade-off**: No automatic config migration
- **Benefit**: Simpler, more predictable behavior
- **Cost**: Users must manually copy config (acceptable for one-time setup)

**Trade-off**: No config validation
- **Benefit**: Keeps implementation simple
- **Cost**: Invalid config only discovered at runtime (existing behavior)

## Migration Plan

### Implementation Steps

1. **Modify brigit script**:
   - Update `enforce()` function config file location logic
   - Add user config directory check
   - Fall back to system default

2. **Add documentation**:
   - Add "Configuration" section to README.md
   - Document default config location for Nix users
   - Explain user config directory option
   - Show default JSON settings
   - Provide copy command example

3. **Update help text** (optional):
   - Consider adding config location info to help

### No user migration needed
- Existing behavior preserved (system default works)
- Users opt-in to customization when needed

### Validation
- ✓ Default config works without user config
- ✓ User config takes precedence when present
- ✓ Documentation is clear and accurate
- ✓ Example commands work correctly

## Open Questions

None - implementation is straightforward.
