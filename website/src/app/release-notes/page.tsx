export default function ReleaseNotesIndex() {
  return (
    <main className="min-h-screen bg-slate-950 text-white">
      <div className="max-w-3xl mx-auto px-6 py-20">
        <p className="text-sm uppercase tracking-[0.3em] text-white/50">Release Notes</p>
        <h1 className="text-4xl font-semibold mt-4">MomentumBar Updates</h1>
        <p className="text-white/60 mt-2">
          Latest updates are linked from individual release pages.
        </p>

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
