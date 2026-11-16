-- Copied into %LOCALAPPDATA%\Autodesk\3dsMax\2027 - 64bit\ENU\scripts\startup\
-- Puts the Callis tools (max/callis, shared from the Mac as \\Mac\ClaudeMax) on
-- Python's path and registers their menu commands.
try (
    python.Execute "import sys\nroot = r'\\\\Mac\\ClaudeMax'\nif root not in sys.path: sys.path.insert(0, root)\nimport callis.startup\ncallis.startup.install()"
) catch (format "[callis] startup failed: %\n" (getCurrentException()))
