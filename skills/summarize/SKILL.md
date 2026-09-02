---
name: summarize
description: Detailed summarization of YouTube videos, Reddit posts, web pages, and LLM shared conversations. Outputs narrative essay-style summaries with bullet points, saved as Markdown files. MUST USE when the user asks to summarize, resume, or explain content from a URL (youtube video, reddit post, web article, shared AI/LLM conversation).
---

# Skill: summarize

Detailed summarization of YouTube videos, Reddit posts, web pages, and LLM shared conversations. Outputs narrative essay-style summaries with bullet points, saved as Markdown files.

## When to use

Invoke this skill when the user asks to summarize, resume, or explain content from a URL. Trigger phrases include:
- "summarize this link..."
- "resume ce lien..." / "resumer cette video..."
- "what's this about https://..."
- "explain this https://..."
- "tl;dr https://..."

## Workflow

### Step 1: Detect content type

Parse the URL to determine the source:

| URL pattern | Type | Fetch method |
|-------------|------|--------------|
| `youtube.com/watch?v=` or `youtu.be/` | YouTube | agent-reach video |
| `reddit.com/r/` or `reddit.com/user/` | Reddit | agent-reach social |
| `chatgpt.com/share/` or `claude.ai/share/` | LLM conversation | Jina reader |
| Anything else | Web page | Jina reader |

### Step 2: Fetch content

Use agent-reach tools based on content type:

#### YouTube videos
```bash
# 1. Try subtitles first
yt-dlp --write-sub --write-auto-sub --sub-lang "ar,fr,en,es,de" --skip-download -o "/tmp/%(id)s" "URL"

# 2. Read the .vtt file
cat /tmp/VIDEO_ID.*.vtt

# 3. If no subtitles or empty, use transcribe fallback
agent-reach transcribe "URL"
```

#### Reddit posts
```bash
# Use rdt-cli or opencli
rdt search "post title or url" --limit 5
# or
opencli reddit search "query" -f yaml
```

#### Web pages and LLM conversations
```bash
# Use Jina reader for clean content
curl -s "https://r.jina.ai/URL"
```

### Step 3: Generate detailed summary

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

### Step 4: Save the summary

Save to `~/summaries/` with this format:

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

### Step 5: Confirm to user

After saving, tell the user:
- File saved to: `~/summaries/filename.md`
- Brief one-line summary of what was summarized

## Error handling

- If content cannot be fetched: report the error and suggest alternatives
- If content is too short or empty: inform the user the source may not have accessible content
- If subtitles are unavailable for YouTube: try `agent-reach transcribe` as fallback
- For Reddit: if API fails, try fetching via Jina reader with the reddit URL

## Quality guidelines

- **Be thorough**: This is a DETAILED summary, not a quick overview. Cover all major points.
- **Stay factual**: Don't add opinions or interpretations not in the source
- **Preserve nuance**: If speakers disagree, note both sides
- **Use the source language**: Don't translate unless asked
- **Include context**: Explain background and significance, not just what was said
