-- Copied into %LOCALAPPDATA%\Autodesk\3dsMax\2027 - 64bit\ENU\scripts\startup\
-- Loads the Claude bridge from the Mac repo (Parallels share ClaudeMax = max/),
-- so edits there need no re-copy.
try (python.ExecuteFile @"\\Mac\ClaudeMax\bridge_startup.py") catch (format "[claude bridge] load failed: %\n" (getCurrentException()))
