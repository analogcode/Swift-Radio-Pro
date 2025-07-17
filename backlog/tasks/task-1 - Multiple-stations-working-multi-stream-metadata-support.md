---
id: task-1
title: 'Multiple stations: working multi-stream metadata support'
status: To Do
assignee: []
created_date: '2025-07-08'
labels: []
dependencies: []
---

## Description
Multi-stream support leverages FRadioPlayer's multi-stream feature. Base setup is in place and the player
can play the streams, but the metadata management doesn't work properly.
 - The station can get stuck in "station stopped"/"Playing..." and stop updating metadata
 - Switching station can leave the metadata still coming from the wrong station; disconnect doesn't seem to work right.
