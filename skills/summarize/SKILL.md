---
name: summarize
description: Detailed summarization of YouTube videos, Reddit posts, web pages, and LLM shared conversations. Outputs narrative essay-style summaries with bullet points, saved as Markdown files. MUST USE when the user asks to summarize, resume, or explain content from a URL (youtube video, reddit post, web article, shared AI/LLM conversation).
---

# Skill: summarize

Detailed summarization of YouTube videos, Reddit posts, web pages, and LLM shared conversations. Outputs narrative essay-style summaries with bullet points, saved as Markdown files.

This skill is **agent-agnostic**: it describes *what* to fetch and *how* to structure the summary, and relies on the host agent harness (opencode, Claude Code, Cursor, etc.) to execute the steps using its **own native tools and CLI** — fetching, running commands, and writing files. No custom helper binary is required.

## When to use

Invoke this skill when the user asks to summarize, resume, or explain content from a URL. Trigger phrases include:
- "summarize this link..."
- "resume ce lien..." / "resumer cette video..."
- "what's this about https://..."
- "explain this https://..."
- "tl;dr https://..."

## Step 0: Agent harness adaptation

This skill only uses general-purpose capabilities that every agent harness exposes. Map them as follows:

| Step | Capability needed | How the agent provides it |
|------|-------------------|---------------------------|
| Fetch YouTube | Run a shell command (`yt-dlp`) | Agent's terminal/run-tool or `agent-reach` backend |
| Fetch web/Reddit | Make an HTTP request (`curl` to Jina) | Agent's fetch/web tool or terminal |
| Fetch LLM conv | Make an HTTP request | Agent's fetch/web tool |
| Write output | Create a Markdown file | Agent's file-write tool (e.g. `Write`, `apply_patch`) |

If the agent has a native web-fetch tool, prefer it for web pages; fall back to `curl https://r.jina.ai/URL` if it returns nothing useful.

## Step 1: Detect content type

Parse the URL to determine the source:

| URL pattern | Type | Fetch method |
|-------------|------|--------------|
| `youtube.com/watch?v=` or `youtu.be/` or `youtube.com/shorts/` | YouTube | `yt-dlp` (subtitles) |
| `reddit.com/r/` or `reddit.com/user/` | Reddit | web fetch / Jina reader |
| `chatgpt.com/share/` or `claude.ai/share/` | LLM conversation | web fetch / Jina reader |
| Anything else | Web page | web fetch / Jina reader |

## Step 2: Fetch content

Use general-purpose commands that any harness can run. Nothing here assumes a specific agent.

#### YouTube videos
```bash
# 1. Try subtitles (Arabic, French, English, Spanish, German)
yt-dlp --write-sub --write-auto-sub --sub-lang "ar,fr,en,es,de" --skip-download -o "/tmp/%(id)s" "URL"

# 2. Read the generated .vtt file
cat /tmp/VIDEO_ID.*.vtt
```

If no subtitles are available, or the content is empty:
- If `agent-reach` is installed: run `agent-reach transcribe "URL"` (audio transcription).
- Otherwise, at minimum capture the metadata so the summary has context:
```bash
yt-dlp --print "%(title)s | %(duration_string)s | %(channel)s" "URL"
```

#### Reddit posts / LLM conversations / Web pages

> **IMPORTANT — pages JavaScript (chatgpt.com/share, claude.ai/share, etc.)** :
> ces pages ne renvoient rien à un fetch direct, tout est rendu côté client JS.
> **Ne pas ouvrir Playwright / Chrome / navigateur headless pour ça** (Chrome
> n'est pas installé et son installation échoue). **Jina Reader extrait déjà le
> texte de ces pages JS.** Utilisez toujours la hiérarchie ci-dessous.

Order of attempts — stop at the first that returns real content (non-empty text):

1. **Jina Reader first** (works from any shell, no browser needed):
```bash
curl -s "https://r.jina.ai/URL"
```
   For `chatgpt.com/share/...` and `claude.ai/share/...` this is the standard
   way and it reliably returns the full conversation as Markdown.

2. If Jina is empty, try the printable/Google-cache-like mirror via Jina with
   a trailing hint, or retry. Some pages need `https://r.jina.ai/https://URL`.

3. **Only as a last resort** — if Jina truly returns nothing AND no native
   fetch tool worked: report to the user that the page is not accessible and
   suggest they copy-paste the text. **Do NOT attempt to install Chrome or run
   Playwright** — that will fail and wastes time. The agent's own web/browser
   tool (if it already has a working browser) may be used, but never install a
   browser during the summary.

For Reddit specifically, if the page is blocked or heavy, try the JSON mirror
`https://www.reddit.com/...json` or a printable mirror via Jina.

## Step 3: Generate detailed summary

Using the fetched content, generate a comprehensive summary with:

1. **Narrative essay-style paragraphs** — write as flowing prose, not bullet points. Cover the full context, arguments, and conclusions.

2. **Key points section** — after the narrative, include organized bullet points for quick reference:
   - Main topics covered
   - Key arguments or findings
   - Notable quotes or statements
   - Conclusions or recommendations

3. **For videos specifically**:
   - Include timestamps for major sections
   - Identify speakers and their roles
   - Note any visual content described

4. **Language**: Match the source language unless the user requests otherwise.

## Step 4: Save the summary

Save to `~/summaries/` with this format. Use the agent's file-writing capability to create the file.

**Filename**: `YYYY-MM-DD-slug.md`
- Date prefix for sorting
- Slug from title (lowercase, hyphens, max 50 chars)
- Example: `2026-09-02-elections-maroc-2026-avenir-politique.md`

**File structure**:
```markdown
---
title: "Full Title from Source"
source: "https://original-url.com"
type: "youtube|reddit|web|llm"
date: "2026-09-02"
duration: "1h45"  # for videos, if available
---

# Title

## Summary

(Narrative essay-style paragraphs — 3-6 paragraphs covering the full content in detail. Write as flowing prose, not bullet points. Include context, main arguments, supporting details, and conclusions.)

## Key Points

- **Topic 1**: Description
- **Topic 2**: Description
- **Topic 3**: Description

(Continue with organized bullet points for quick reference)

## Notable Quotes

> "Quote from speaker/author" — Person Name

(Include 2-3 significant quotes if available)

## Sources & References

- [Original Link](URL)
- Any other links mentioned in the content
```

## Step 5: Confirm to user

After saving, tell the user:
- File saved to: `~/summaries/filename.md`
- Brief one-line summary of what was summarized

## Error handling

- If content cannot be fetched: report the error and suggest alternatives
- If content is too short or empty: inform the user the source may not have accessible content
- For YouTube without subtitles: rely on metadata, or use `agent-reach transcribe` if installed
- For Reddit: if the page API fails, try fetching the `...json` endpoint or a Jina-reader mirror
- If the agent's native fetch tool fails, fall back to `curl -s "https://r.jina.ai/URL"`
- **JavaScript pages (chatgpt.com/share, claude.ai/share)**: Jina Reader
  (`curl -s "https://r.jina.ai/URL"`) renders these fine — prefer it over any
  browser. **Never install Chrome / run Playwright / npx playwright install**
  as part of this skill; if that path is reached, stop, and ask the user to
  paste the text instead.

## Quality guidelines

- **Be thorough**: This is a DETAILED summary, not a quick overview. Cover all major points.
- **Stay factual**: Don't add opinions or interpretations not in the source
- **Preserve nuance**: If speakers disagree, note both sides
- **Use the source language**: Don't translate unless asked
- **Include context**: Explain background and significance, not just what was said
