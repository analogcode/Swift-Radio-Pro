
<!-- BACKLOG.MD GUIDELINES START -->
# Instructions for the usage of Backlog.md CLI Tool

## 1. Source of Truth

- Tasks live under **`backlog/tasks/`** (drafts under **`backlog/drafts/`**).
- Every implementation decision starts with reading the corresponding Markdown task file.
- Project documentation is in **`backlog/docs/`**.
- Project decisions are in **`backlog/decisions/`**.

## 2. Defining Tasks

### **Title**

Use a clear brief title that summarizes the task.

### **Description**: (The **"why"**)

Provide a concise summary of the task purpose and its goal. Do not add implementation details here. It
should explain the purpose and context of the task. Code snippets should be avoided.

### **Acceptance Criteria**: (The **"what"**)

List specific, measurable outcomes that define what means to reach the goal from the description. Use checkboxes (`- [ ]`) for tracking.
When defining `## Acceptance Criteria` for a task, focus on **outcomes, behaviors, and verifiable requirements** rather
than step-by-step implementation details.
Acceptance Criteria (AC) define *what* conditions must be met for the task to be considered complete.
They should be testable and confirm that the core purpose of the task is achieved.
**Key Principles for Good ACs:**

- **Outcome-Oriented:** Focus on the result, not the method.
- **Testable/Verifiable:** Each criterion should be something that can be objectively tested or verified.
- **Clear and Concise:** Unambiguous language.
- **Complete:** Collectively, ACs should cover the scope of the task.
- **User-Focused (where applicable):** Frame ACs from the perspective of the end-user or the system's external behavior.

    - *Good Example:* "- [ ] User can successfully log in with valid credentials."
    - *Good Example:* "- [ ] System processes 1000 requests per second without errors."
    - *Bad Example (Implementation Step):* "- [ ] Add a new function `handleLogin()` in `auth.ts`."

### Task file

Once a task is created it will be stored in `backlog/tasks/` directory as a Markdown file with the format
`task-<id> - <title>.md` (e.g. `task-42 - Add GraphQL resolver.md`).

### Additional task requirements

- Tasks must be **atomic** and **testable**. If a task is too large, break it down into smaller subtasks.
  Each task should represent a single unit of work that can be completed in a single PR.

- **Never** reference tasks that are to be done in the future or that are not yet created. You can only reference
  previous
  tasks (id < current task id).

- When creating multiple tasks, ensure they are **independent** and they do not depend on future tasks.   
  Example of wrong tasks splitting: task 1: "Add API endpoint for user data", task 2: "Define the user model and DB
  schema".  
  Example of correct tasks splitting: task 1: "Add system for handling API requests", task 2: "Add user model and DB
  schema", task 3: "Add API endpoint for user data".

## 3. Recommended Task Anatomy

```markdown
# task‑42 - Add GraphQL resolver

## Description (the why)

Short, imperative explanation of the goal of the task and why it is needed.

## Acceptance Criteria (the what)

- [ ] Resolver returns correct data for happy path
- [ ] Error response matches REST
- [ ] P95 latency ≤ 50 ms under 100 RPS

## Implementation Plan (the how)

1. Research existing GraphQL resolver patterns
2. Implement basic resolver with error handling
3. Add performance monitoring
4. Write unit and integration tests
5. Benchmark performance under load

## Implementation Notes (only added after working on the task)

- Approach taken
- Features implemented or modified
- Technical decisions and trade-offs
- Modified or added files
```

## 6. Implementing Tasks

Mandatory sections for every task:

- **Implementation Plan**: (The **"how"**) Outline the steps to achieve the task. Because the implementation details may
  change after the task is created, **the implementation notes must be added only after putting the task in progress**
  and before starting working on the task.
- **Implementation Notes**: Document your approach, decisions, challenges, and any deviations from the plan. This
  section is added after you are done working on the task. It should summarize what you did and why you did it. Keep it
  concise but informative.

**IMPORTANT**: Do not implement anything else that deviates from the **Acceptance Criteria**. If you need to
implement something that is not in the AC, update the AC first and then implement it or create a new task for it.

## 2. Typical Workflow

```bash
# 1 Identify work
backlog task list -s "To Do" --plain

# 2 Read details & documentation
backlog task 42 --plain
# Read also all documentation files in `backlog/docs/` directory.
# Read also all decision files in `backlog/decisions/` directory.

# 3 Start work: assign yourself & move column
backlog task edit 42 -a @{yourself} -s "In Progress"

# 4 Add implementation plan before starting
backlog task edit 42 --plan "1. Analyze current implementation\n2. Identify bottlenecks\n3. Refactor in phases"

# 5 Break work down if needed by creating subtasks or additional tasks
backlog task create "Refactor DB layer" -p 42 -a @{yourself} -d "Description" --ac "Tests pass,Performance improved"

# 6 Complete and mark Done
backlog task edit 42 -s Done --notes "Implemented GraphQL resolver with error handling and performance monitoring"
```

### 7. Final Steps Before Marking a Task as Done

Always ensure you have:

1. ✅ Marked all acceptance criteria as completed (change `- [ ]` to `- [x]`)
2. ✅ Added an `## Implementation Notes` section documenting your approach
3. ✅ Run all tests and linting checks
4. ✅ Updated relevant documentation

## 8. Definition of Done (DoD)

A task is **Done** only when **ALL** of the following are complete:

1. **Acceptance criteria** checklist in the task file is fully checked (all `- [ ]` changed to `- [x]`).
2. **Implementation plan** was followed or deviations were documented in Implementation Notes.
3. **Automated tests** (unit + integration) cover new logic.
4. **Static analysis**: linter & formatter succeed.
5. **Documentation**:
    - All relevant docs updated (any relevant README file, backlog/docs, backlog/decisions, etc.).
    - Task file **MUST** have an `## Implementation Notes` section added summarising:
        - Approach taken
        - Features implemented or modified
        - Technical decisions and trade-offs
        - Modified or added files
6. **Review**: self review code.
7. **Task hygiene**: status set to **Done** via CLI (`backlog task edit <id> -s Done`).
8. **No regressions**: performance, security and licence checks green.

⚠️ **IMPORTANT**: Never mark a task as Done without completing ALL items above.

## 9. Handy CLI Commands

| Purpose          | Command                                                                |
|------------------|------------------------------------------------------------------------|
| Create task      | `backlog task create "Add OAuth"`                                      |
| Create with desc | `backlog task create "Feature" -d "Enables users to use this feature"` |
| Create with AC   | `backlog task create "Feature" --ac "Must work,Must be tested"`        |
| Create with deps | `backlog task create "Feature" --dep task-1,task-2`                    |
| Create sub task  | `backlog task create -p 14 "Add Google auth"`                          |
| List tasks       | `backlog task list --plain`                                            |
| View detail      | `backlog task 7 --plain`                                               |
| Edit             | `backlog task edit 7 -a @{yourself} -l auth,backend`                   |
| Add plan         | `backlog task edit 7 --plan "Implementation approach"`                 |
| Add AC           | `backlog task edit 7 --ac "New criterion,Another one"`                 |
| Add deps         | `backlog task edit 7 --dep task-1,task-2`                              |
| Add notes        | `backlog task edit 7 --notes "We added this and that feature because"` |
| Mark as done     | `backlog task edit 7 -s "Done"`                                        |
| Archive          | `backlog task archive 7`                                               |
| Draft flow       | `backlog draft create "Spike GraphQL"` → `backlog draft promote 3.1`   |
| Demote to draft  | `backlog task demote <task-id>`                                        |

## 10. Tips for AI Agents

- **Always use `--plain` flag** when listing or viewing tasks for AI-friendly text output instead of using Backlog.md
  interactive UI.
- When users mention to create a task, they mean to create a task using Backlog.md CLI tool.

<!-- BACKLOG.MD GUIDELINES END -->

---

# ConfigClient Integration Progress (In-Progress)

## Summary
Implementing ConfigClient from RadioSpiral3 into RadioSpiral app. ConfigClient provides dynamic station loading from Azuracast with intelligent fallback chains and zero shipped API keys.

## Completed Tasks
1. ✅ **ConfigClient implementation and testing** - ConfigClient fully implemented, tested, and committed
   - 14 tests passing (all local and live server tests)
   - Tests at: `RadioSpiral/ConfigClientTests/ConfigClientTests.swift`
   - Code at: `RadioSpiral/ConfigClient/ConfigClient.swift`
   - Public API approach verified (demo.azuracast.com)
   - Fallback chain logic tested including edge cases (exclusion)

2. ✅ **Add ConfigClient to main RadioSpiral target** - ConfigClient added to RadioSpiral target and building successfully
   - Previously verified: `xcodebuild build -scheme RadioSpiral -configuration Debug` → BUILD SUCCEEDED
   - ConfigClient.swift is in RadioSpiral/ConfigClient/ directory
   - ConfigClient was added to RadioSpiral target's Sources build phase

3. ✅ **Create StationConfig → RadioStation Converter** - Converter fully implemented and tested
   - **Implementation:**
     - Extracted `StationConfig` struct to dedicated file: `RadioSpiral/ConfigClient/StationConfig.swift`
     - Created converter initializer extension on RadioStation: `init(from stationConfig: StationConfig)`
     - Maps all 8 StationConfig fields to RadioStation: name, streamURL, imageURL, desc, longDesc, serverName, shortCode, defaultDJ
   - **Project Integration:**
     - Added StationConfig.swift to project.pbxproj with proper file references and build phase entries
     - Added to ConfigClientTests target (ID: 71CA8E8A2EC57A5100F7F157)
     - Added to RadioSpiral main target (ID: 71CA8E8A2EC57A5200F7F157)
   - **Tests Passing:**
     - `testStationConfigToDictionary` - Verifies StationConfig creation and field assignment
     - `testStationConfigFromFetchedData` - Verifies fetched data can be converted
     - All 16 ConfigClientTests passing (14 original + 2 new converter tests)
   - **Build Status:** BUILD SUCCEEDED - Main RadioSpiral target builds without errors

   **Key Files Modified:**
   - Created: `RadioSpiral/ConfigClient/StationConfig.swift`
   - Modified: `RadioSpiral/ConfigClient/ConfigClient.swift` (removed duplicate StationConfig definition)
   - Modified: `RadioSpiral/Model/RadioStation.swift` (added converter extension lines 107-124)
   - Modified: `RadioSpiral.xcodeproj/project.pbxproj` (registered StationConfig in build phases)
   - Modified: `RadioSpiral/ConfigClientTests/ConfigClientTests.swift` (added converter tests)

4. ✅ **Implement ConfigClient Fallback Lookups in MetadataManager** - Fallback chain enhanced with ConfigClient
   - **Implementation:**
     - Added ConfigClient.shared property to StationMetadataManager (line 74)
     - Enhanced getFallbackMetadata() to lookup station info from ConfigClient by shortCode
     - Fallback metadata now prioritizes: Azuracast > FRadioPlayer > ConfigClient+RadioStation > RadioStation
     - Made ConfigClient and public methods public for cross-module access
   - **Name Conflict Resolution:**
     - Renamed internal error type: `DataError` → `ConfigClientError`
     - Renamed internal config struct: `Config` → `ConfigClientDebug`
     - Fixed pbxproj: Added ConfigClient.swift to RadioSpiral target's Compile Sources
   - **Test Coverage:**
     - New test: `testConfigClientCachingForFallback` - Verifies station lookup by shortCode
     - Confirms all fallback fields available: name, desc, defaultDJ
     - 17 ConfigClientTests passing (16 previous + 1 new)
   - **Build Status:** BUILD SUCCEEDED - All tests passing

5. ✅ **Update DataManager to Use ConfigClient for Dynamic Station Loading** - Full integration with smart fallback chain
   - **Implementation:**
     - Add ConfigClient.shared property to DataManager for station fetching
     - Create loadConfigClient() method to fetch and convert stations
     - Convert StationConfig to RadioStation using converter extension
     - Separate handlers for ConfigClient (StationsResult) vs HTTP/Local (DataResult)
   - **Configuration:**
     - Add Config.useConfigClient flag (default: true) for easy toggling
     - Implement smart fallback chain: ConfigClient → Local JSON → HTTP
     - Preserve backward compatibility with existing loading mechanisms
   - **Smart Loading Order:**
     1. ConfigClient (dynamic Azuracast/fallback config)
     2. Local JSON (stations.json bundled in app)
     3. HTTP (remote stations.json)
   - **Test Coverage:**
     - All 17 ConfigClientTests still passing
     - Build: SUCCESS with no errors
   - **Build Status:** BUILD SUCCEEDED - All tests passing

## Remaining Tasks
- [ ] Test integrated system on device

## Key Code Locations
- **ConfigClient**: `RadioSpiral/ConfigClient/ConfigClient.swift`
- **StationConfig**: `RadioSpiral/ConfigClient/StationConfig.swift` (public struct, 22 lines)
- **ConfigClient Tests**: `RadioSpiral/ConfigClientTests/ConfigClientTests.swift` (16 tests, all passing)
- **RadioStation Model**: `RadioSpiral/Model/RadioStation.swift`
- **Converter Extension**: Lines 107-124 in RadioStation.swift (`init(from stationConfig: StationConfig)`)

## Test Config Files
- `RadioSpiral/ConfigClientTests/test-config-with-fallback.json`
- `RadioSpiral/ConfigClientTests/test-config-with-real-server.json`
- `RadioSpiral/ConfigClientTests/test-config-live-azuracast.json`

## Current Known Good State
- All 16 ConfigClientTests passing (14 original + 2 converter tests)
- ConfigClient & StationConfig building into both RadioSpiral and ConfigClientTests targets
- RadioStation converter working with full field mapping
- Main RadioSpiral target builds successfully
- Project structure clean with StationConfig in dedicated file

## Session Summary (Sessions 2-3)
**Duration**: Efficient token usage across two checkpoint commits
**Work Completed**:

**Session 2: ConfigClient Converter Integration**
1. ✅ Fixed build error by extracting StationConfig to separate file
2. ✅ Properly registered StationConfig.swift in project.pbxproj
3. ✅ Implemented RadioStation converter extension (init from StationConfig)
4. ✅ Created converter tests
5. ✅ Checkpoint commit: "Extract StationConfig and implement RadioStation converter"

**Session 2: MetadataManager Fallback Integration**
6. ✅ Integrated ConfigClient into MetadataManager
7. ✅ Enhanced fallback metadata chain with ConfigClient lookups
8. ✅ Resolved naming conflicts (DataError → ConfigClientError, Config → ConfigClientDebug)
9. ✅ Added ConfigClient.swift to RadioSpiral target's compile sources
10. ✅ Created fallback chain test (testConfigClientCachingForFallback)
11. ✅ Checkpoint commit: "Integrate ConfigClient into MetadataManager for fallback lookups"

**Session 3: DataManager Dynamic Station Loading**
12. ✅ Added Config.useConfigClient flag for configuration
13. ✅ Integrated ConfigClient into DataManager
14. ✅ Implemented smart fallback chain: ConfigClient → Local → HTTP
15. ✅ Created loadConfigClient() with StationConfig→RadioStation conversion
16. ✅ Separate handlers for different result types
17. ✅ Full backward compatibility maintained

**Session 3 Results**:
- Completed: Full ConfigClient integration across all major components
- Tests: 17/17 ConfigClientTests passing
- Build: SUCCESS with no errors
- Architecture: Dynamic station loading with intelligent fallback chain

**Current Status**:
- ConfigClient fully integrated and functional
- Smart fallback chain implemented (ConfigClient → Local JSON → HTTP)
- MetadataManager enhanced with ConfigClient fallback lookups
- DataManager now uses ConfigClient for dynamic station loading
- All code changes backward compatible

**Next Steps for Future Sessions**:
- Device testing of full integrated system
- Performance optimization if needed
- Consider caching layer improvements
