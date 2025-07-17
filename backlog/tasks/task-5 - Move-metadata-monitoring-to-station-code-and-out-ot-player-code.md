---
id: task-5
title: Move metadata monitoring to station code and out of player code
status: To Do
assignee: []
created_date: '2025-07-08'
labels: []
dependencies: []
---

## Description
The metadata monitoring is in the nowPlaying classes, which is the wrong place. This probably should be an Observable object in the Station management space, since station switching etc. lives there.
