# Nakãya Portal

Working context for Claude Code. Read this before touching anything.

## What this is

Nakãya is an AI-born visual and mythological universe: a parallel dimension
reaching Earth, with AI as the bridge. Started fall 2022. Won Svenska
Designpriset 2023 (People's Choice). Lives at nakaya.world and
@nakaya.world on Instagram.

The Portal is the digital oracle deck app for that universe. It is a living
symbolic world. It is **not** a chatbot, not a wellness app, and not a
conventional oracle-card library. If a change starts making it feel like any
of those three, stop and flag it.

Central message: everything is connected.

## Canon

Core elements: Ȯ (Mysteriet), Mount Ịsa (the Source), the river
Ngarriguárna, Divine Amnesia, Kuàña, The Maw (Noravük).

Seven regions (isáñas), mapped to chakras by dominant color:

| Region | Chakra | Theme |
|---|---|---|
| Jérikko | Root | Survival |
| Ingíui | Sacral | Creativity |
| Nãi | Will | Identity, direction |
| Tángo | Heart | Love, grief |
| Tígua | Voice | Honesty, expression |
| Astã | Inner eye | Intuition |
| Amaskás | Crown | Unity |

Also canon: masculine and feminine rivers, the Ocean of Union, body patterns
mirroring truth. The Maw swallowed the ocean, severed the rivers, and is
still expanding.

### Canon rules

- **Preserve diacritics exactly.** Nakãya, Jérikko, Ingíui, Nãi, Tángo,
  Tígua, Astã, Amaskás, Ȯ, Ịsa, Ngarriguárna, Vermáya, Noravük, Kuàña.
- **Ask before any retcon.** Do not quietly adjust established lore to make
  a feature work.
- Distinguish canon from working versions, old lore, and strategy notes.
  When unsure which you are looking at, ask.
- The Sage and the Oracle must not appear as characters in the book.

## Voice

- No preachy tone. No generic fantasy.
- **Never use em dashes (—) in app copy.**
- Card and encounter text: slightly longer, with real information. Easy to
  understand while still deep and useful. Not cryptic, not abstract for its
  own sake.
- Lore is revealed piece by piece along the journey. The parallel-dimension
  mirror concept should be taught easily and continuously, never dumped.

## Design direction

Extremely premium and clean. Dark, with vibrant color. Reference points:
OpenAI and Apple for restraint, awwwards-style editorial sites for
typography and pacing. Real Nakãya artwork throughout, never placeholder or
generated stand-ins.

## Current build (v5, React/TypeScript)

- Encounters drawn from real artwork; regions assigned by dominant color
- 10 meetings per region to unlock, with distance-weighted encounter odds
- Mount Ịsa gated behind all regions complete
- Reflections are a public wall, optional anonymity
- The Tide: shared world-state against The Maw
- Dream Gate: dusk offering to dawn dream
- Deeds plus a generative Pattern sigil
- Chronicle and personal recap
- Weavers program
- Being memory, river journey through the isáñas, anonymous River exchange,
  send-a-being codes, Kin weekly bonds, community Sightings naming, hidden
  appearance conditions

Declined for now: being voices, hard app-close.

## Working preferences

- Surgical edits. Change what was asked, leave the rest alone.
- Explain what changed and why, briefly.
- Flag it rather than guessing when a request touches canon.

## Known cleanup

The main file embeds all artwork as base64, which makes it very large. Worth
extracting to an `assets/` folder with real image files and imports.
