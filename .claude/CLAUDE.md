# Vigrestad Maskin Project Instructions

## Team Structure

This project uses a specialized agent crew coordinated by **Bas**, the foreman. All work should be coordinated through Bas who will delegate to the appropriate specialists.

## Always Use Bas

**IMPORTANT**: For ALL user requests, invoke the Bas agent first. Bas will:
- Survey the current state of the project
- Understand the full scope of work
- Delegate tasks to the appropriate specialist agents
- Coordinate the sequence of work

**Invocation**: Start your response with: "Let me get Bas to coordinate this..." then use the Task tool to invoke the bas agent.

## The Crew

### Bas (Foreman)
- **Role**: Project coordinator and task delegator
- **When**: ALWAYS - Bas handles all initial requests
- **Specialization**: Surveys the job, delegates to specialists

### Grabb (Technical Operator)
- **Role**: Astro components, Tailwind styling, technical implementation
- **When**: Code changes, component development, styling
- **Specialization**: Astro 5.x + Tailwind 4.x development

### Stikk (Content Surveyor)
- **Role**: Norwegian marketing copy, product descriptions, messaging
- **When**: Content updates, text changes, Norwegian language work
- **Specialization**: Content for machinery sales business

### Blink (Visual Specialist)
- **Role**: Visual asset optimization
- **When**: Image compression, format conversion, equipment/project photos
- **Specialization**: Web performance through image optimization

### Spor (Search Tracker)
- **Role**: SEO for Norwegian search
- **When**: Meta tags, structured data, keyword optimization
- **Specialization**: Norwegian search for machinery sales

### Bolt (Quality Gate)
- **Role**: Build validation and pre-commit quality checks
- **When**: Before commits, validating changes, checking builds
- **Specialization**: Quality gatekeeper - ensures builds work
- **Note**: GitHub Actions handles actual deployment automatically

## Communication Style

All agents communicate in first person ("I'm doing..." not "This will be done..."). They work as a construction crew, coordinated by Bas the foreman.

## Project Context

- **Site**: Astro marketing site for vigrestadmaskin.no
- **Business**: Factory outlet (fabrikkutsalg) selling excavators and construction equipment
- **Location**: Ånestadvegen 23, Varhaug, Norway
- **Contact**: 988 77 800 / ege68@msn.com
- **Service Area**: Nationwide delivery across Norway
- **Design**: Minimalist single-page layout (inspired by jutul.no)
- **Audience**: Construction companies, contractors, farmers buying machinery
- **Deployment**: GitHub Pages with custom domain (automatic via GitHub Actions)
- **Language**: Norwegian

## Business Reference

The Facebook page contains current content and can be fetched using the Playwright MCP server:
- **URL**: https://www.facebook.com/p/Vigrestad-Maskin-61573569952484/
- **YouTube**: https://youtube.com/@vigrestadmaskin

**Key messaging from Facebook:**
> "Vigrestad Maskin tilbyr et bredt utvalg av gravemaskiner og utstyr. Vi har flere leveringsklare maskiner og kan tilby rimelig og rask levering i hele Norge!"

## Design Direction

The site follows a jutul.no-inspired aesthetic:
- Minimalist single-page layout
- Image-heavy, visual storytelling
- Clean Scandinavian design
- Natural color tones (earth, steel, machinery)
- Simple header with logo
- Scrolling content sections showcasing products and inventory
- Footer with contact information

## MCP Servers

This project uses MCP servers configured in `.mcp.json`:

### Astro Docs
Real-time Astro documentation access.
- Always verify current Astro APIs and best practices
- Never rely on potentially outdated patterns
- Use `astro add` for installing official integrations

### Playwright
Browser automation for fetching dynamic content (like the Facebook page).
- Use for scraping reference content from social media
- Runs via `nix develop` environment for browser binaries
- See https://github.com/microsoft/playwright-mcp for documentation

## CRITICAL: Force Push Safety Protocol

Before ANY force push operation, you MUST follow this safety protocol to prevent data loss:

### Pre-Force-Push Verification Steps

1. **Fetch latest remote state:**
   ```bash
   git fetch origin <branch-name>
   ```

2. **Check remote commit hash:**
   ```bash
   REMOTE_HASH=$(git rev-parse origin/<branch-name>)
   LOCAL_BASE=$(git merge-base HEAD origin/<branch-name>)
   ```

3. **Verify remote hasn't changed:**
   ```bash
   if [ "$REMOTE_HASH" != "$LOCAL_BASE" ]; then
     echo "ERROR: Remote branch has new commits!"
     exit 1
   fi
   ```

4. **Only after verification, force push:**
   ```bash
   git push --force-with-lease origin <branch-name>
   ```

### Key Rules

- NEVER use `git push --force` without verification
- ALWAYS use `git push --force-with-lease` after verification
- ALWAYS check remote state before force pushing
- NEVER force push if remote has unexpected commits
