# Claude Code Workflows

This directory contains workflow files and checklists for development with Claude Code.

## Files

### library-check-workflow.md
Comprehensive checklist for evaluating and choosing libraries before implementing functionality from scratch.

**When to use:**
- Before implementing any new feature
- When you think "I need to add X"
- Before writing complex algorithms
- When considering dependencies

**How to use:**
1. Read the checklist
2. Run `make libs` or `make find-lib FEATURE="x"`
3. Follow the decision process
4. Document your choice

## Quick Commands

```bash
# Show recommended libraries
make libs

# Search for libraries by feature
make find-lib FEATURE="collision"
make find-lib FEATURE="pathfinding"
make find-lib FEATURE="camera"
make find-lib FEATURE="animation"

# View full library database
cat LIBRARIES.md
```

## Philosophy

**Search first, implement last.**

1. Check if Love2D has built-in functionality
2. Search for well-maintained libraries
3. Evaluate options using the decision matrix
4. Only write custom code when necessary

This approach:
- Saves development time
- Reduces bugs (battle-tested code)
- Keeps focus on game-specific features
- Maintains code quality

## Integration with Claude

When working with Claude Code, reference these workflows:

**For Claude:**
```
Before implementing [feature], please:
1. Run `make find-lib FEATURE="[feature]"`
2. Review LIBRARIES.md
3. Follow .claude/library-check-workflow.md
4. Recommend a library OR explain why custom code is better
```

**For Developers:**
When asking Claude to implement features, remind it to check for existing libraries first.

## Updating Workflows

These workflows are living documents. Update them when you:
- Discover better libraries
- Find better decision criteria
- Learn from mistakes (e.g., chose wrong library)
- Identify new common patterns

---

**Maintained by**: Holdfast Development Team
**Last Updated**: 2026-03-15
