export default function ReleaseNotesIndex() {
  return (
    <main className="min-h-screen bg-slate-950 text-white">
      <div className="max-w-3xl mx-auto px-6 py-20">
        <p className="text-sm uppercase tracking-[0.3em] text-white/50">Release Notes</p>
        <h1 className="text-4xl font-semibold mt-4">MomentumBar Updates</h1>
        <p className="text-white/60 mt-2">
          What’s new in MomentumBar and links to detailed release artifacts.
        </p>

        <div className="mt-8 rounded-2xl border border-white/10 bg-white/5 p-6">
          <div className="flex flex-col gap-2 sm:flex-row sm:items-baseline sm:justify-between">
            <h2 className="text-xl font-semibold">Version 1.0.4</h2>
            <span className="text-sm text-white/50">Build 6</span>
          </div>
          <ul className="mt-4 space-y-2 text-white/70">
            <li>Announcements badge + mark-all-read, plus onboarding delay.</li>
            <li>Calendar UX refresh, last sync time, and clearer error states.</li>
            <li>Updates screen with manual check and last check status.</li>
            <li>Settings reorganized (About / License / Update) and diagnostics toggle.</li>
            <li>Performance: reduced idle redraws for better battery life.</li>
          </ul>
          <div className="mt-6 flex flex-wrap gap-3">
            <a
              href="/downloads/MomentumBar-1.0.4.dmg"
              className="inline-flex items-center gap-2 rounded-lg bg-white text-slate-900 px-4 py-2 font-semibold"
            >
              Download DMG
            </a>
            <a
              href="/downloads/MomentumBar-1.0.4.zip"
              className="inline-flex items-center gap-2 rounded-lg border border-white/20 px-4 py-2 font-semibold text-white"
            >
              Download ZIP
            </a>
          </div>
        </div>

        <div className="mt-8 rounded-2xl border border-white/10 bg-white/5 p-6">
          <h2 className="text-xl font-semibold">Release feed</h2>
          <p className="text-white/60 mt-2">
            The app reads updates from our Sparkle appcast feed.
          </p>
          <a
            href="/appcast.xml"
            className="inline-flex mt-4 items-center gap-2 rounded-lg bg-white text-slate-900 px-4 py-2 font-semibold"
          >
            View appcast.xml
          </a>
        </div>
      </div>
    </main>
  )
}
