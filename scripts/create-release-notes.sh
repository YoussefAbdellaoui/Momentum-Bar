#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-}"

if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 1.2.3"
  exit 1
fi

TARGET_DIR="website/src/app/release-notes/$VERSION"
TARGET_FILE="$TARGET_DIR/page.tsx"

if [[ -f "$TARGET_FILE" ]]; then
  echo "Release notes already exist at $TARGET_FILE"
  exit 0
fi

mkdir -p "$TARGET_DIR"

cat <<PAGE > "$TARGET_FILE"
export default function ReleaseNotes() {
  return (
    <main className="min-h-screen bg-slate-950 text-white">
      <div className="max-w-3xl mx-auto px-6 py-20">
        <p className="text-sm uppercase tracking-[0.3em] text-white/50">Release Notes</p>
        <h1 className="text-4xl font-semibold mt-4">MomentumBar $VERSION</h1>
        <p className="text-white/60 mt-2">Published on {new Date().toLocaleDateString()}</p>

        <section className="mt-10 space-y-6 text-white/80">
          <div>
            <h2 className="text-xl font-semibold text-white">Highlights</h2>
            <ul className="list-disc list-inside mt-3 space-y-2">
              <li>Describe the headline feature here.</li>
              <li>Add one more key improvement.</li>
            </ul>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white">Fixes</h2>
            <ul className="list-disc list-inside mt-3 space-y-2">
              <li>Bug fix summary.</li>
            </ul>
          </div>
        </section>
      </div>
    </main>
  )
}
PAGE

echo "Created $TARGET_FILE"
