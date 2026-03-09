# Psychology of Meaningful Social Connection and Conscious Tech Design

Research synthesis for the goback app: psychological frameworks, neurochemical models, and ethical design principles that inform a social platform built for human wellbeing rather than engagement extraction.

---

## 1. Dunbar's Layers and Circle Design

### The Social Brain Hypothesis

Robin Dunbar's social brain hypothesis (1992, 1993, 1998) established that primate neocortex size correlates directly with social group size. For humans, extrapolation predicts a natural group size of approximately 150 individuals -- now known as "Dunbar's number." This is not merely an average; it has been validated across extraordinary breadth: Anglo-Saxon villages in the Domesday Book, Bronze Age settlements, military fighting units, church congregations, Christmas card distribution lists, Facebook friend networks, and telephone calling patterns.

### The Fractal Layers: 5 / 15 / 50 / 150

Dunbar's number is not a single threshold but a fractal series of nested layers, each roughly three times the size of the one inside it:

| Layer | Size | Label | Emotional Quality |
|-------|------|-------|-------------------|
| 1 | ~5 | Support clique / intimate core | These are the people who would drop everything to come to your aid. Deepest emotional bonds, daily contact. |
| 2 | ~15 | Sympathy group | Close friends with regular emotional maintenance. Grief and celebration are shared here. |
| 3 | ~50 | Affinity group | People you would invite to a personal gathering. Meaningful but less emotionally intense. |
| 4 | ~150 | Active network | The outer boundary of relationships where you know each person's name, history, and social relation to you. |

Beyond 150, layers at ~500 and ~1,500 represent acquaintances and recognized faces, but these lack the reciprocal trust that defines meaningful connection.

### Implications for goback Circle Design

- **Circle size caps should reflect Dunbar's layers.** A maximum of 150 members per circle preserves the cognitive boundary within which trust and social cohesion are maintainable. Circles larger than this will fragment into sub-groups regardless of design.
- **Differentiate circle experiences by size.** A circle of 5 operates under different social dynamics than a circle of 50. Smaller circles could unlock features that depend on intimacy (e.g., reaction-only responses, ephemeral voice notes), while larger circles might emphasize communal rituals (e.g., group check-ins, shared prompts).
- **The 15-person sympathy group is the sweet spot for active sharing.** Research shows this is the layer where emotional maintenance is frequent enough to sustain vulnerability but large enough to avoid the intensity fatigue of the innermost circle.
- **Individual variation exists.** Extroverts have slightly larger Dunbar numbers than introverts. The system should not enforce rigid caps but provide gentle scaffolding (e.g., "Your circle is growing -- consider whether everyone here still feels close").
- **Groups larger than 150 built on a single shared dimension (e.g., interest, cause) are inherently fragile.** If that dimension weakens, the community evaporates. goback should never compete on scale; it should compete on depth.

---

## 2. Ephemeral Content Psychology

### Scarcity and Perceived Value

Ephemeral content leverages one of the most robust findings in behavioral economics: scarcity increases perceived value. When a photo or video will disappear in 24 hours, the viewer's brain treats it as more valuable than permanent content. This is not merely FOMO -- it is a fundamental shift in how attention is allocated. Scarce stimuli receive deeper cognitive processing because the opportunity cost of ignoring them is higher.

### Authenticity Through Impermanence

Because ephemeral content cannot be endlessly polished, it encourages spontaneity. Users know that a post will not persist on a permanent profile, so the psychological pressure to curate a flawless self-image diminishes. This reduces what Erving Goffman called "impression management" -- the exhausting work of maintaining a public persona. The result is content that is more genuine, more vulnerable, and therefore more connective.

### The FOMO Paradox: "Missing Out" vs. "Being Present"

Standard social media weaponizes FOMO through infinite timelines and algorithmic surfacing of what you missed. Ephemeral content creates a different dynamic:

- **Healthy scarcity**: Users check in intentionally because content has a window, not because an algorithm guilt-trips them about falling behind.
- **Acceptance of missing**: When content disappears, there is no permanent record of what was missed. This reduces the rumination loop ("I should have checked earlier") that characterizes unhealthy FOMO.
- **Presence over consumption**: The 24-hour window encourages being present during the window rather than binge-consuming a backlog. The experience is closer to a conversation than a library.

### Implications for goback

- **24h auto-deletion is psychologically sound.** It reduces curation pressure, increases authenticity, and creates healthy scarcity without algorithmic manipulation.
- **Do not add "save" or "archive" features for shared content.** The moment content becomes permanent, the authenticity benefit collapses. Users will revert to curating for posterity.
- **Frame the 24h window as a feature, not a limitation.** Language matters: "Your moment is live for 24 hours" conveys presence. "Content expires in 24 hours" conveys loss.
- **Missed content should leave no trace.** No "you missed 3 posts" notifications. If you were not present, the moment passed -- and that is psychologically healthy.

---

## 3. Self-Determination Theory (SDT)

Self-Determination Theory (Deci & Ryan, 1985, 2000) identifies three basic psychological needs whose satisfaction predicts wellbeing: autonomy, competence, and relatedness. When these needs are met, intrinsic motivation flourishes. When they are frustrated, wellbeing deteriorates and external regulation (addiction-like patterns) fills the void.

### Autonomy: "I choose this"

Autonomy is the sense of psychological freedom and volition in one's actions. It is not independence -- it is the felt experience that one's behavior is self-endorsed.

**How goback serves autonomy:**
- **Daily usage limits are autonomy-supportive, not autonomy-restricting.** This is counterintuitive. Traditional social media removes choice by design (infinite scroll, autoplay, dark patterns). goback's limits restore the user's sense of agency: "I chose how much time I spend." Research on self-imposed constraints shows that freely chosen limits enhance the feeling of control.
- **Manual lockout is a pure autonomy feature.** The user literally decides to restrict their own future access. This is self-determination in its strongest form.
- **No algorithmic feed.** When an algorithm decides what you see, autonomy is undermined. When you choose which circle to check, autonomy is preserved.

### Competence: "I can do this effectively"

Competence is the feeling of mastery and effectiveness in reaching desired goals.

**Where goback currently serves competence:**
- Successfully sharing a moment (post creation flow)
- Managing circle membership (inviting, organizing)
- Understanding and using lockout / time limits effectively

**Where competence could be strengthened:**
- Provide gentle feedback on social engagement patterns ("You have been consistently present in your circle this week") without gamification or scores.
- Make the app easy to learn and master. Complexity frustrates competence. goback's simplicity is a competence asset.

### Relatedness: "I belong and am cared for"

Relatedness is the experience of mutual warmth, connection, and belonging.

**How goback serves relatedness:**
- **Circles are inherently relatedness structures.** Invite-only membership creates a trust boundary that signals "you belong here."
- **Ephemeral shared content creates shared experience.** When circle members view the same temporary content, they share a moment in time -- similar to the relatedness boost of watching a sunset together.
- **Small group sizes enable reciprocity.** In a group of 15, each person's contribution is visible and valued. In a group of 10,000, individual contributions vanish.

### Implications for goback

- **Frame limits as choices, not restrictions.** UX language should position time limits and lockout as tools the user wields, not rules imposed on them.
- **Prioritize relatedness features.** Of the three needs, relatedness is the one most directly served by a social app and the one most frustrated by mainstream social media. Every design decision should ask: "Does this deepen the feeling of mutual connection?"
- **Be cautious with competence.** Gamification (streaks, scores, badges) can satisfy competence but quickly devolves into extrinsic motivation, undermining autonomy. If competence features are added, they should be reflective (showing patterns) not competitive (ranking against others).

---

## 4. Neurochemistry of Social Connection

### Dopamine: The "Wanting" System

Dopamine drives anticipation, novelty-seeking, and reward prediction. It is the neurochemical of "wanting" rather than "liking." Social media platforms have mastered dopamine exploitation through:

- **Variable ratio reinforcement**: Unpredictable rewards (likes, comments, new content) keep users checking compulsively, the same mechanism that drives slot machine addiction.
- **Infinite scroll**: Removes natural stopping cues, keeping the dopamine loop running indefinitely.
- **Social comparison metrics**: Visible follower counts and like counts create a dopamine-driven status game.

Dopamine-driven engagement feels urgent and compulsive. Users leave these platforms feeling depleted, not satisfied.

### Oxytocin: The "Bonding" System

Oxytocin is released during moments of intimacy, trust, reciprocity, and vulnerability. It strengthens emotional bonds between individuals. Key triggers include:

- **Physical touch and presence** (limited in digital contexts, but see below)
- **Reciprocal disclosure**: Sharing something personal and having it received with warmth
- **Trust signals**: Knowing that shared information is safe
- **Small group bonding**: Face-to-face interaction in trusted groups

Research shows that oxytocin and dopamine interact: oxytocin modulates the dopamine reward system, redirecting reward-seeking toward social bonding rather than novelty. Over time in relationships, oxytocin and vasopressin become more dominant, fostering deep connection and emotional security.

### The Digital Oxytocin Challenge

Digital interactions generally lack the embodied presence needed for peak oxytocin production. However, specific conditions can approximate it:

- **Reciprocal vulnerability in a trusted context** (sharing a personal moment in a private circle)
- **Temporal co-presence** (knowing that others are viewing your content right now, within the same 24h window)
- **Small group identity** (the feeling that "these are my people")

### Implications for goback

- **Eliminate dopamine traps.** No like counts, no follower metrics, no algorithmic variable-reward feed. Every one of these is a dopamine exploitation mechanism.
- **Maximize conditions for oxytocin.** Private circles (trust), ephemeral content (vulnerability), small groups (intimacy), invite-only access (safety) -- these are all oxytocin-favorable conditions.
- **Design for "liking" not "wanting."** Users should leave goback feeling connected and warm (oxytocin), not craving more (dopamine). The difference is between satisfaction and depletion.
- **Consider "seen by" indicators over "like" buttons.** Knowing someone saw your moment creates a sense of reciprocal presence. A like button creates a variable reward game. "Seen by" triggers belonging; "liked by" triggers status-seeking.
- **Resist the temptation to add reactions or emoji responses** beyond minimal acknowledgment. Each additional reaction type adds a layer of variable reward and social comparison.

---

## 5. Constraint as Empowerment

### Commitment Devices and the Odysseus Contract

A commitment device is a strategy by which an individual voluntarily restricts their own future choices in order to align short-term behavior with long-term preferences. The canonical example is Odysseus ordering his crew to bind him to the mast so he could hear the Sirens' song without jumping overboard.

The dual-self model (Fudenberg & Levine) formalizes this: the "planning self" (time 0) has different preferences than the "experiencing self" (time 1). The planning self values long-term wellbeing; the experiencing self is pulled by immediate impulse. Commitment devices allow the planning self to constrain the experiencing self, preventing regretted choices.

### Implementation Intentions (Gollwitzer)

Peter Gollwitzer's research on implementation intentions -- "if-then" plans for behavior change -- shows that pre-committing to specific actions in specific situations dramatically increases follow-through. A meta-analysis of 94 studies (8,000+ participants) found medium-to-large effect sizes. The mechanism: forming an implementation intention creates a strong mental association between a cue and a response, making the desired behavior semi-automatic.

### Self-Efficacy and Internal Locus of Control

When users successfully use self-imposed limits, they experience increased self-efficacy (Bandura) -- the belief that they can exert control over their own behavior. This feeds an internal locus of control: the feeling that outcomes are determined by one's own choices rather than external forces. This is the opposite of the learned helplessness that characterizes compulsive social media use, where users report feeling unable to stop despite wanting to.

### Field Evidence

Research on commitment contracts for smoking cessation found that financial commitment devices increased quit rates by 3.4 to 5.7 percentage points (a ~38% relative increase). Software tools that block internet access for predetermined periods have demonstrated similar self-regulation benefits.

### Implications for goback

- **Time limits and lockout are commitment devices.** Frame them explicitly as tools of self-mastery, not punishments. The user is Odysseus; the app is the mast.
- **Support implementation intentions.** Allow users to set their time limits in advance ("I will use goback for 15 minutes after dinner"). The specificity of if-then planning is what makes it effective.
- **Celebrate successful self-regulation.** When a user's daily time ends, the exit screen should reinforce their agency: "You chose to spend 15 minutes connecting today" -- not "Your time is up."
- **Lockout should feel empowering, not restrictive.** The UX of manual lockout should convey strength ("Taking a break"), not failure ("Locked out").
- **Make the commitment visible but private.** Users benefit from knowing they set a limit. They do not benefit from others knowing their limit (which could create shame or social comparison).

---

## 6. Ritual and Habit Formation

### The Crucial Distinction: Ritual vs. Addiction

Ryder Carroll (creator of the Bullet Journal method) draws a critical line: habits are automatic behaviors done with little conscious thought, while rituals are intentional actions imbued with meaning beyond their instrumental value. A habit is brushing your teeth. A ritual is a morning gratitude practice. The key differences:

| Dimension | Habit | Ritual | Addiction |
|-----------|-------|--------|-----------|
| Awareness | Low (automatic) | High (intentional) | Low (compulsive) |
| Meaning | Functional | Symbolic / emotional | Empty / depleting |
| Agency | Neutral | Chosen | Lost |
| Flexibility | Moderate | Moderate | Rigid / distressing if prevented |
| Post-behavior feeling | Neutral | Fulfilled | Craving or regret |

### How Conscious Design Creates Healthy Rituals

goback can create rituals by satisfying three conditions:

1. **Temporal anchoring**: A consistent time or trigger (e.g., "I check my circle after dinner"). Time-boxing creates anticipation, which research on delayed gratification shows enhances the experience itself.
2. **Intentional entry**: The user consciously decides to open the app, rather than being pulled in by a notification dopamine hit. No autoplay, no infinite scroll, no "while you were away" bait.
3. **Meaningful closure**: The experience has a natural endpoint that leaves the user feeling complete, not hungry for more (see Section 9 on the "Good Enough" Principle).

### The B.J. Fogg Behavior Model Applied

Fogg's model states that behavior occurs when three elements converge: Motivation, Ability, and a Prompt.

- **Motivation**: The desire to connect with one's circle (intrinsic, relatedness-driven).
- **Ability**: The app must be simple enough that checking in requires minimal friction. Fogg's "Tiny Habits" research shows that lowering ability thresholds is more effective than increasing motivation.
- **Prompt**: This is where ethical design matters. A notification is a prompt. The question is whether the prompt serves the user's goals or the platform's engagement metrics.

### Implications for goback

- **Design for ritual, not habit.** The app should feel like a daily practice, not an automatic reflex. Subtle design cues (a moment of pause before content loads, a warm visual transition) signal intentionality.
- **Time-boxing creates anticipation, not deprivation.** When users know they have 15 minutes, the time becomes precious. Research on scarcity and time constraints shows that bounded experiences are savored more deeply.
- **Notifications should be invitations, not interruptions.** A single daily "Your circle shared moments today" notification is a ritual prompt. Push notifications for every post is an addiction trigger.
- **Provide natural closure.** When all content has been viewed, show a clear "You are caught up" state. Do not generate more content, suggest other users to follow, or trigger the Zeigarnik effect (see Section 9).

---

## 7. Trust and Vulnerability in Small Groups

### Psychological Safety (Edmondson)

Amy Edmondson's research on psychological safety -- the shared belief that a group is safe for interpersonal risk-taking -- found that it was the single most important factor distinguishing high-performing teams. Google's Project Aristotle confirmed this across 180+ teams: psychological safety predicted team effectiveness more than any other variable.

In the context of a social sharing app, psychological safety means: "I can share an unpolished, genuine moment without fear of judgment, screenshot, or it being shared outside this group."

### Vulnerability as Connection Engine (Brown)

Brene Brown's research establishes that vulnerability -- defined as emotional exposure, uncertainty, and risk -- is the birthplace of connection. Key principles:

- **"Vulnerability minus boundaries is not vulnerability."** Indiscriminate sharing is not connection; it is exposure. True vulnerability requires a trusted container.
- **"Share with people who have earned the right to hear your story."** Trust is built incrementally through small acts of disclosure that are received with warmth. This maps directly to the invite-only, small-circle model.
- **Brown advocates for "brave spaces" over "safe spaces"** -- environments where people feel courageous enough to be honest, not merely comfortable. goback circles should aspire to this.

### The Trust Boundary of Invite-Only Access

Invite-only access creates what sociologists call a "trust boundary" -- a clear demarcation between insiders and outsiders. This boundary:

- Signals commitment (you were chosen to be here)
- Creates reciprocal obligation (if I was invited, I should contribute)
- Reduces free-rider behavior (no anonymous lurkers diluting the group's intimacy)
- Enables vulnerability (what is shared here stays here)

### Small Group Dynamics and Deeper Bonds

Research consistently shows that relationship depth is inversely correlated with group size. In groups of 5-15:
- Each member's contribution is visible and valued
- Social loafing decreases
- Reciprocity norms are stronger (you notice if someone has not shared)
- Conflict resolution is more effective (you cannot hide in a crowd)
- Identity fusion is higher (the group becomes part of self-concept)

### Implications for goback

- **The invite-only model is psychologically essential, not just a growth strategy.** It creates the trust boundary without which vulnerability-based connection cannot occur.
- **Never add public profiles or discoverability.** The moment content can be seen by strangers, the vulnerability benefit collapses.
- **Consider a "circle covenant" -- a visible shared agreement** about what content stays in the circle. Even a simple "What is shared here stays here" banner reinforces psychological safety.
- **New member onboarding in existing circles matters.** Adding a stranger to an intimate circle disrupts psychological safety. Consider a "warm introduction" flow where existing members vouch for new additions.
- **The absence of screenshots or saving mechanisms is a trust signal.** Even the perception that content could be saved undermines vulnerability. (Note: technical prevention is imperfect, but the design signal matters.)

---

## 8. Ethical Engagement Principles

### Tristan Harris and the Center for Humane Technology

Harris's core framework: technology should serve human wellbeing, not extract human attention for profit. His concept of "human downgrading" describes an interconnected system of mutually reinforcing harms -- addiction, distraction, isolation, polarization, misinformation -- that weakens human capacity. His "Time Well Spent" movement asks: did this interaction leave the user better off?

**Principles for goback:**
- Every feature should pass the "Time Well Spent" test: does the user feel the time was meaningful?
- The business model should never depend on maximizing time-in-app. Align revenue with user wellbeing, not against it.
- Avoid what Harris calls the "race to the bottom of the brain stem" -- competing for attention through increasingly base stimuli.

### Cal Newport and Digital Minimalism

Newport defines digital minimalism as "applying the art of knowing how much is just enough to personal technology." His framework:

- **The digital declutter**: Remove all optional technologies, then reintroduce only those that serve deeply held values.
- **Solitude deprivation**: The state of never being alone with your own thoughts, caused by constant digital input. Social apps should leave room for solitude.
- **High-quality leisure**: Analog activities that engage skills and produce satisfying results. Digital tools should complement, not replace, these.

**Principles for goback:**
- goback should be the app that survives a digital declutter because it genuinely serves the value of human connection.
- Usage limits prevent solitude deprivation. The app gets out of the way.
- goback should facilitate in-person connection, not replace it. Consider features that bridge digital and physical (e.g., "Who is nearby?" for circle members, without location tracking).

### Nir Eyal: The Hook Model Inverted

Eyal's Hook Model (Trigger -> Action -> Variable Reward -> Investment) was designed to create habit-forming products. But Eyal himself distinguishes sharply between habits and addiction: "Addiction, by definition, harms people. There is no such thing as a good addiction."

The Hook Model can be inverted for ethical use:

| Hook Stage | Exploitative Version | Ethical (goback) Version |
|------------|---------------------|--------------------------|
| Trigger | Push notifications for every interaction | Single daily digest or user-set reminder |
| Action | Open app, infinite scroll | Open app, view circle's moments |
| Reward | Variable (likes, comments, algorithmic surprises) | Consistent (connection, warmth, shared presence) |
| Investment | Data lock-in, social graph dependency | Genuine relationships that deepen over time |

The critical distinction: ethical engagement produces consistent, warm rewards (oxytocin) rather than variable, exciting rewards (dopamine).

### B.J. Fogg's Two Maxims

Fogg's ethical principles for persuasive technology design:
1. **Help people do what they already want to do.** Users want to connect with close friends. goback facilitates that existing desire.
2. **Help people feel successful.** Every interaction should leave users feeling they accomplished something meaningful, not that they wasted time.

### Implications for goback -- Design Decision Checklist

Every new feature should be evaluated against these questions:

1. **Harris test**: Does this leave the user feeling their time was well spent?
2. **Newport test**: Would this survive a digital declutter -- does it serve a deeply held value?
3. **Eyal test**: Is the reward pattern consistent (bonding) or variable (craving)?
4. **Fogg test**: Does this help users do what they already want to do, and feel successful doing it?
5. **Brown test**: Does this enable or undermine vulnerability in a trusted context?
6. **Dunbar test**: Does this work within human cognitive limits for social relationships?

If a feature fails any of these tests, it should be redesigned or discarded.

---

## 9. The "Good Enough" Principle

### Satisficing vs. Maximizing (Schwartz)

Barry Schwartz's research on the Paradox of Choice distinguishes two decision-making strategies:

- **Maximizers** evaluate all options to find the best one. They experience more regret, more social comparison, and less satisfaction.
- **Satisficers** accept the first option that meets their criteria for "good enough." They are happier, more optimistic, and more satisfied with their choices.

Mainstream social media creates maximizers: there is always more content, a better post, a more interesting profile. The infinite feed tells users "you have not seen enough." goback should create satisficers: users who check in with their circle, feel connected, and leave.

### The Zeigarnik Effect and Closure

The Zeigarnik effect (1927) shows that incomplete tasks create persistent cognitive tension. The mind continues to process unfinished business, creating the sensation of "needing to go back." Social media exploits this ruthlessly: there is always an unfinished feed, an unread notification, an unseen story.

goback must do the opposite: provide closure. When users have seen all their circle's content, the experience is complete. There is no "load more," no "you might also like," no artificial incompleteness.

### Post-Interaction Emotional Residue

Every technology interaction leaves an emotional residue -- a lingering feeling after the app is closed. Research on affect regulation suggests three possible residues:

| Residue | Cause | Example |
|---------|-------|---------|
| Positive warmth | Genuine connection, felt reciprocity | "My friends are doing well, and they saw my moment" |
| Anxious craving | Incomplete loops, variable rewards | "I wonder if anyone liked my post yet" |
| Guilty depletion | Time wasted, compulsive scrolling | "I just spent 45 minutes on nothing" |

goback should exclusively produce the first residue.

### Implications for goback

- **Design for completion, not continuation.** Every session should have a natural, satisfying endpoint.
- **"You are caught up" is the most important screen in the app.** It should feel warm and conclusive, not like a gate blocking more content.
- **Never create artificial Zeigarnik tension.** No "1 unseen post" badges that persist. No notification counts. No red dots.
- **The exit experience matters as much as the entry experience.** When a user closes goback, the last thing they see should reinforce connection and closure: "You connected with 4 friends today" or simply a warm, calm visual.
- **Resist "one more thing" patterns.** No recommended circles, no suggested friends, no trending content. When the user's circle interaction is complete, the app's job is done.
- **Measure "post-session satisfaction" not "session length."** If the product metric is "how do users feel after using goback?" rather than "how long did they use goback?", every design decision will orient toward closure and warmth.

---

## Summary: Psychological Design Principles for goback

| # | Principle | Psychological Foundation |
|---|-----------|------------------------|
| 1 | Cap circles at Dunbar-informed sizes | Social brain hypothesis, cognitive limits |
| 2 | Keep content ephemeral with no save/archive | Scarcity effect, authenticity, reduced curation pressure |
| 3 | Frame limits as tools of self-mastery | Commitment devices, self-efficacy, SDT autonomy |
| 4 | Eliminate variable reward mechanisms | Dopamine vs. oxytocin, consistent vs. variable reward |
| 5 | Design for ritual, not habit | Intentionality, temporal anchoring, meaningful closure |
| 6 | Maintain invite-only trust boundaries | Psychological safety, vulnerability research, trust formation |
| 7 | Provide completion and closure in every session | Zeigarnik effect (inverted), satisficing, emotional residue |
| 8 | Test every feature against the ethical design checklist | Harris, Newport, Eyal, Fogg, Brown, Dunbar |
| 9 | Prioritize relatedness above all other needs | SDT, oxytocin pathways, small group dynamics |
| 10 | Measure post-session satisfaction, not engagement time | "Good enough" principle, Time Well Spent |

---

## Key References

- Dunbar, R. I. M. (1992, 1993, 1998). The social brain hypothesis. *Evolutionary Anthropology*.
- Deci, E. L., & Ryan, R. M. (1985, 2000). Self-determination theory. *Handbook of Self-Determination Research*.
- Schwartz, B. (2002). Maximizing versus satisficing: Happiness is a matter of choice. *Journal of Personality and Social Psychology*.
- Gollwitzer, P. M. (1999). Implementation intentions: Strong effects of simple plans. *American Psychologist*.
- Brown, B. (2012). *Daring Greatly: How the Courage to Be Vulnerable Transforms the Way We Live, Love, Parent, and Lead*.
- Edmondson, A. (1999). Psychological safety and learning behavior in work teams. *Administrative Science Quarterly*.
- Fudenberg, D., & Levine, D. K. (2006). A dual-self model of impulse control. *American Economic Review*.
- Bandura, A. (1977). Self-efficacy: Toward a unifying theory of behavioral change. *Psychological Review*.
- Eyal, N. (2014). *Hooked: How to Build Habit-Forming Products*. Portfolio/Penguin.
- Eyal, N. (2019). *Indistractable: How to Control Your Attention and Choose Your Life*. BenBella Books.
- Fogg, B. J. (2002). *Persuasive Technology: Using Computers to Change What We Think and Do*. Morgan Kaufmann.
- Fogg, B. J. (2019). *Tiny Habits: The Small Changes That Change Everything*. Houghton Mifflin Harcourt.
- Newport, C. (2019). *Digital Minimalism: Choosing a Focused Life in a Noisy World*. Portfolio/Penguin.
- Harris, T. / Center for Humane Technology. "Time Well Spent" framework and "Human Downgrading" concept.
- Zeigarnik, B. (1927). On finished and unfinished tasks. *Psychologische Forschung*.
- Goffman, E. (1959). *The Presentation of Self in Everyday Life*. Anchor Books.
