/*
 * notitle.dylib — injected into 3ds Max's Coherence stub (WinAppHelper) so that,
 * on Max's full-screen Space, the top edge reveals only the macOS menu bar.
 *
 * WHY: Parallels gives Max's window its own macOS full-screen Space (the user's
 * choice — see max/CLAUDE.md § Coherence). AppKit then slides the window's title
 * bar ("3ds Max 2027", traffic lights) down with the menu bar whenever the pointer
 * touches the top edge. That strip lives in a separate NSToolbarFullScreenWindow
 * owned by this process; we keep it invisible and click-through. The menu bar is
 * the system's and is untouched.
 *
 * HOW IT GETS IN: LSEnvironment DYLD_INSERT_LIBRARIES in the stub's Info.plist
 * (the stub is ad-hoc signed, no hardened runtime, so dyld honours it). Applied by
 * max/notitle/install.sh — re-run by coherence_fullscreen.sh because Parallels
 * rewrites its stubs. Log: /tmp/coherence_notitle.log.
 *
 * THE VEIL (2026-10-16): a launching Max is jarring — splash, default layout, docks
 * popping, clean mode hiding them, full screen. The stub starts with Max, so while Max
 * launches every window of this stub is alpha 0 + click-through, with `hud spin` at the
 * bottom middle. Max's callis.startup writes ../.state/startup.json {"phase": "starting"
 * → "ready"} (ready = clean mode + full screen settled); the veil lifts (fade) on a
 * "ready" newer than this stub, once no /tmp/.max_veil_hold (max_restart.py, while it
 * reloads the scene) is fresh. Not veiled when the stub starts beside a live Max
 * (nav.json heartbeat fresh) or a Max that recovers (heartbeat before any "starting").
 * Backstops: no "starting" in 240 s, no "ready" 90 s after it, hold > 15 min.
 * QUITTING: Max closing un-fullscreens and redraws its chrome for ~10 s. A "quitting"
 * phase (callis.startup on preSystemShutdown; max_restart.py before quitMax) newer than
 * the last veil change veils every window again; the spinner hides once Max is gone
 * (nav.json heartbeat stale) unless the hold says a relaunch follows. Lifts if Max is
 * still answering 60 s later (a quit that didn't happen) or on com.callis.maxveil.lift.
 * Windows of other processes (the licensing nag) aren't ours — never veiled.
 *
 * Build: clang -arch arm64 -dynamiclib -fobjc-arc -framework AppKit -o notitle.dylib notitle.m
 */
#import <AppKit/AppKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <spawn.h>

static void logf_(NSString *fmt, ...) {
    va_list ap; va_start(ap, fmt);
    NSString *s = [[NSString alloc] initWithFormat:fmt arguments:ap];
    va_end(ap);
    FILE *f = fopen("/tmp/coherence_notitle.log", "a");
    if (!f) return;
    fprintf(f, "[%s] %d %s\n", [[NSDate date].description UTF8String], getpid(), s.UTF8String);
    fclose(f);
}

static BOOL isRevealWindow(NSWindow *w) {
    return [NSStringFromClass([w class]) isEqualToString:@"NSToolbarFullScreenWindow"];
}

static void hush(NSWindow *w) {
    if (w.alphaValue != 0) w.alphaValue = 0;
    if (!w.ignoresMouseEvents) w.ignoresMouseEvents = YES;
}

static void hushAll(void) {
    for (NSWindow *w in NSApp.windows)
        if (isRevealWindow(w)) hush(w);
}

// The reveal window is (re)ordered in on every hover; catch it before it draws.
static IMP origOrder;
static void swzOrder(NSWindow *self, SEL _cmd, NSWindowOrderingMode m, NSInteger rel) {
    if (m != NSWindowOut) hush(self);
    ((void (*)(id, SEL, NSWindowOrderingMode, NSInteger))origOrder)(self, _cmd, m, rel);
}

// ── The veil ─────────────────────────────────────────────────────────────────

static BOOL veiled = NO;
static NSDate *stubStart;
static NSString *stateDir;            // max/.state, from this dylib's own path
static NSDate *startingSeen;          // a "starting" newer than this stub was seen
static NSDate *quitAt;                // veiled for a closing Max (nil = launch veil)
static NSDate *phaseSeen;             // startup.json mtime already acted on
static BOOL spinHidden;
static char veilKey;                  // per window: @[wanted alpha, wanted ignoresMouse]

static IMP origAlpha;
static void swzAlpha(NSWindow *self, SEL _cmd, CGFloat a) {
    if (veiled && !isRevealWindow(self)) {
        NSArray *v = objc_getAssociatedObject(self, &veilKey);
        objc_setAssociatedObject(self, &veilKey, @[@(a), v ? v[1] : @(self.ignoresMouseEvents)],
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        a = 0;
    }
    ((void (*)(id, SEL, CGFloat))origAlpha)(self, _cmd, a);
}

static void veilWindow(NSWindow *w) {
    if (!veiled || isRevealWindow(w) || objc_getAssociatedObject(w, &veilKey)) return;
    objc_setAssociatedObject(w, &veilKey, @[@(w.alphaValue), @(w.ignoresMouseEvents)],
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    w.alphaValue = 0;                 // clamped by swzAlpha
    w.ignoresMouseEvents = YES;
}

static IMP origOrderAll;
static void swzOrderAll(NSWindow *self, SEL _cmd, NSWindowOrderingMode m, NSInteger rel) {
    if (m != NSWindowOut) veilWindow(self);
    ((void (*)(id, SEL, NSWindowOrderingMode, NSInteger))origOrderAll)(self, _cmd, m, rel);
    if (veiled && quitAt && m != NSWindowOut)
        logf_(@"quit: order in %@ #%ld alpha=%.2f %@", NSStringFromClass([self class]), (long)self.windowNumber,
              self.alphaValue, NSStringFromRect(self.frame));
}

static void hud(const char *verb) {
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"bin/hud"];
    char *args[] = {(char *)path.fileSystemRepresentation, (char *)verb, NULL};
    // our environ carries DYLD_INSERT_LIBRARIES — hud mustn't load this dylib
    NSMutableArray *env = [NSMutableArray array];
    [NSProcessInfo.processInfo.environment enumerateKeysAndObjectsUsingBlock:^(NSString *k, NSString *v, BOOL *stop) {
        if (![k hasPrefix:@"DYLD_"]) [env addObject:[NSString stringWithFormat:@"%@=%@", k, v]];
    }];
    char **envp = calloc(env.count + 1, sizeof(char *));
    for (NSUInteger i = 0; i < env.count; i++) envp[i] = strdup([env[i] UTF8String]);
    pid_t pid;
    int rc = posix_spawn(&pid, args[0], NULL, NULL, args, envp);
    for (NSUInteger i = 0; i < env.count; i++) free(envp[i]);
    free(envp);
    if (rc == 0)
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{ waitpid(pid, NULL, 0); });
}

static NSDate *mtime(NSString *path) {
    return [NSFileManager.defaultManager attributesOfItemAtPath:path error:nil].fileModificationDate;
}

// Back to alpha 1, not the alpha seen while veiled: the full-screen transition sets
// the main window's alpha behind our back, so the "wanted" value read 0 and the lifted
// Max stayed invisible (2026-10-16). Coherence windows are opaque; the reveal strip
// is the only one kept at 0. No animator fade: on the full-screen window it never
// landed either. Re-asserted twice, for a transition still finishing.
static void unveilAll(void) {
    for (NSWindow *w in NSApp.windows) {
        if (isRevealWindow(w)) continue;
        NSArray *v = objc_getAssociatedObject(w, &veilKey);   // kept: the re-asserts need it
        if (!v) continue;
        if (w.ignoresMouseEvents != [v[1] boolValue]) w.ignoresMouseEvents = [v[1] boolValue];
        if (w.alphaValue < 1) w.alphaValue = 1;
    }
}

static void lift(NSString *why) {
    if (!veiled) return;
    veiled = NO;
    logf_(@"veil lifted after %.1f s: %@", -stubStart.timeIntervalSinceNow, why);
    hud("hide");
    quitAt = nil;
    unveilAll();
    for (int ms = 500; ms <= 3000; ms *= 6)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, ms * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            if (!veiled) unveilAll();
        });
}

static BOOL holdFresh(void) {
    NSDate *hm = mtime(@"/tmp/.max_veil_hold");
    return hm && hm.timeIntervalSinceNow > -900;
}

static BOOL maxAlive(void) {
    NSDate *nm = mtime([stateDir stringByAppendingPathComponent:@"nav.json"]);
    return nm && nm.timeIntervalSinceNow > -5;
}

static void checkQuit(void) {
    if (!spinHidden && !maxAlive() && !holdFresh()) {
        spinHidden = YES;
        hud("hide");                  // Max is gone and nothing relaunches it
    }
    if (maxAlive() && quitAt.timeIntervalSinceNow < -60) lift(@"Max didn't quit in 60 s");
}

static void checkVeil(void) {
    if (!veiled) return;
    if (quitAt) return checkQuit();
    NSTimeInterval age = -stubStart.timeIntervalSinceNow;
    NSString *sp = [stateDir stringByAppendingPathComponent:@"startup.json"];
    NSDate *sm = mtime(sp);
    NSString *phase = nil;
    if (sm && [sm compare:stubStart] == NSOrderedDescending) {
        NSData *d = [NSData dataWithContentsOfFile:sp];
        NSDictionary *j = d ? [NSJSONSerialization JSONObjectWithData:d options:0 error:nil] : nil;
        if ([j isKindOfClass:NSDictionary.class]) phase = j[@"phase"];
            if (phase && !startingSeen) startingSeen = NSDate.date;
        // "ready" + settle s (Max's last full-screen fix is that far out)
        if ([phase isEqualToString:@"ready"] && sm.timeIntervalSinceNow > -[j[@"settle"] doubleValue])
            phase = @"settling";
    }
    BOOL held = holdFresh();
    if ([phase isEqualToString:@"ready"] && !held) return lift(@"ready");
    if (!startingSeen) {
        NSDate *nm = mtime([stateDir stringByAppendingPathComponent:@"nav.json"]);
        if (nm && [nm compare:stubStart] == NSOrderedDescending) return lift(@"a running Max answered");
        if (age > 240) return lift(@"no startup in 240 s");
    } else if (!held && startingSeen.timeIntervalSinceNow < -90) {
        return lift(@"not ready 90 s after starting");
    }
}

static void veilAll(void) {
    for (NSWindow *w in NSApp.windows) veilWindow(w);
    hud("spin");
    spinHidden = NO;
    [NSTimer scheduledTimerWithTimeInterval:0.25 repeats:YES block:^(NSTimer *t) {
        checkVeil();
        if (!veiled) [t invalidate];
    }];
}

static void quitVeil(void) {
    if (veiled) return;
    veiled = YES;
    quitAt = NSDate.date;
    logf_(@"veiled while Max quits");
    for (NSWindow *w in NSApp.windows)   // fresh "wanted" values: the lift's are stale
        objc_setAssociatedObject(w, &veilKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    veilAll();
}

// Watches startup.json for "quitting" while not veiled (one stat a second).
static void watchQuit(void) {
    [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer *t) {
        if (veiled) return;
        NSString *sp = [stateDir stringByAppendingPathComponent:@"startup.json"];
        NSDate *sm = mtime(sp);
        if (!sm || [sm compare:stubStart] != NSOrderedDescending || [sm isEqualToDate:phaseSeen]) return;
        phaseSeen = sm;
        NSData *d = [NSData dataWithContentsOfFile:sp];
        NSDictionary *j = d ? [NSJSONSerialization JSONObjectWithData:d options:0 error:nil] : nil;
        if ([j isKindOfClass:NSDictionary.class] && [j[@"phase"] isEqualToString:@"quitting"]) quitVeil();
    }];
}

static void startVeil(void) {
    stubStart = NSDate.date;
    Dl_info info;
    if (dladdr((const void *)startVeil, &info) && info.dli_fname)
        stateDir = [[[[NSString stringWithUTF8String:info.dli_fname] stringByDeletingLastPathComponent]
                     stringByDeletingLastPathComponent] stringByAppendingPathComponent:@".state"];
    if (!stateDir) return;
    Method m = class_getInstanceMethod([NSWindow class], @selector(setAlphaValue:));
    origAlpha = method_setImplementation(m, (IMP)swzAlpha);
    m = class_getInstanceMethod([NSWindow class], @selector(orderWindow:relativeTo:));
    origOrderAll = method_setImplementation(m, (IMP)swzOrderAll);
    watchQuit();
    if (maxAlive()) {
        logf_(@"no veil: Max is already running");
        return;
    }
    veiled = YES;
    logf_(@"veiled while Max starts");
    veilAll();
}

__attribute__((constructor)) static void notitle_init(void) {
    logf_(@"loaded into %@", NSProcessInfo.processInfo.processName);
    if (![NSProcessInfo.processInfo.processName isEqualToString:@"WinAppHelper"]) return;   // a child that inherited DYLD_
    dispatch_async(dispatch_get_main_queue(), ^{
        // escape hatch: distributed notification com.callis.maxveil.lift (max/CLAUDE.md) re-lifts
        [NSDistributedNotificationCenter.defaultCenter addObserverForName:@"com.callis.maxveil.lift" object:nil
            queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *n) {
            veiled ? lift(@"asked") : unveilAll();
        }];
        startVeil();      // before the reveal-window override, which then chains through it
        Class c = NSClassFromString(@"NSToolbarFullScreenWindow");
        Method m = c ? class_getInstanceMethod(c, @selector(orderWindow:relativeTo:)) : NULL;
        if (m) {
            // add an override on the subclass itself so NSWindow's IMP stays intact
            origOrder = method_getImplementation(m);
            if (!class_addMethod(c, @selector(orderWindow:relativeTo:), (IMP)swzOrder, method_getTypeEncoding(m)))
                origOrder = method_setImplementation(class_getInstanceMethod(c, @selector(orderWindow:relativeTo:)), (IMP)swzOrder);
        } else {
            logf_(@"NSToolbarFullScreenWindow not found — notification fallback only");
        }
        NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
        for (NSNotificationName n in @[NSWindowDidEnterFullScreenNotification, NSWindowDidUpdateNotification])
            [nc addObserverForName:n object:nil queue:nil usingBlock:^(NSNotification *note) {
                NSWindow *w = note.object;
                if ([n isEqualToString:NSWindowDidEnterFullScreenNotification])
                    logf_(@"full screen: %@ styleMask=%#lx windows=%@", NSStringFromClass([w class]), (unsigned long)w.styleMask,
                          [[NSApp.windows valueForKey:@"className"] componentsJoinedByString:@","]);
                if (isRevealWindow(w)) hush(w); else if (w.styleMask & NSWindowStyleMaskFullScreen) hushAll();
            }];
    });
}
