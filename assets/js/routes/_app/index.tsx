import { createFileRoute } from '@tanstack/react-router';

function DashboardLanding() {
  return (
    <div className="min-h-[calc(100vh-4rem)] bg-gradient-to-br from-slate-900 via-slate-950 to-slate-900">
      <div className="mx-auto flex w-full max-w-6xl flex-col gap-10 px-6 py-16 text-slate-100 sm:px-10 lg:flex-row lg:items-start lg:gap-14">
        <section className="flex-1">
          <span className="inline-flex items-center gap-2 rounded-full bg-white/10 px-4 py-1 text-xs font-semibold uppercase tracking-[0.2em] text-slate-200 backdrop-blur transition hover:bg-white/20">
            Next up
          </span>
          <h1 className="mt-6 text-4xl font-bold tracking-tight sm:text-5xl">
            Shape the future of your Photowalk experience
          </h1>
          <p className="mt-4 max-w-xl text-base leading-relaxed text-slate-300">
            We cleared out the old todos so you can dream bigger. Start mapping the
            stories, shoots, and creative rituals that will power the next version of
            Photowalk.
          </p>

          <div className="mt-8 flex flex-wrap items-center gap-4">
            <a
              href="/roadmap"
              className="group inline-flex items-center justify-center rounded-full bg-sky-500 px-6 py-3 text-sm font-semibold text-white shadow-lg shadow-sky-500/30 transition will-change-transform hover:-translate-y-0.5 hover:bg-sky-400 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-sky-300"
            >
              Explore roadmap
              <span className="ml-2 inline-flex h-5 w-5 items-center justify-center rounded-full bg-white/20 transition group-hover:bg-white/40">
                →
              </span>
            </a>
            <a
              href="/teams"
              className="inline-flex items-center justify-center rounded-full border border-white/30 px-6 py-3 text-sm font-semibold text-slate-100 transition hover:border-white/50 hover:bg-white/10 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white/60"
            >
              Invite collaborators
            </a>
          </div>
        </section>

        <aside className="flex w-full max-w-lg flex-col gap-4 lg:mt-4">
          <div className="rounded-3xl border border-white/10 bg-white/5 p-6 shadow-[0_25px_60px_-20px_rgba(15,23,42,0.6)] backdrop-blur">
            <h2 className="text-lg font-semibold text-white">Launch checklist</h2>
            <p className="mt-2 text-sm text-slate-300">
              A focused guide for transforming the product idea into the next flagship
              release. Use it as a springboard for ideation sessions.
            </p>
            <ul className="mt-4 space-y-3 text-sm text-slate-100">
              <li className="flex items-start gap-3 rounded-2xl bg-black/10 px-4 py-3 transition hover:bg-black/20">
                <span className="mt-1 inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-sky-500/80 text-xs font-semibold text-white">
                  1
                </span>
                <div>
                  <p className="font-semibold">Define the Photowalk narrative</p>
                  <p className="text-xs text-slate-300">Clarify who you serve and the journeys they embark on.</p>
                </div>
              </li>
              <li className="flex items-start gap-3 rounded-2xl bg-black/10 px-4 py-3 transition hover:bg-black/20">
                <span className="mt-1 inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-sky-500/80 text-xs font-semibold text-white">
                  2
                </span>
                <div>
                  <p className="font-semibold">Design the field toolkit</p>
                  <p className="text-xs text-slate-300">Prototype the planning flows, maps, and shared moodboards.</p>
                </div>
              </li>
              <li className="flex items-start gap-3 rounded-2xl bg-black/10 px-4 py-3 transition hover:bg-black/20">
                <span className="mt-1 inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-sky-500/80 text-xs font-semibold text-white">
                  3
                </span>
                <div>
                  <p className="font-semibold">Pilot with creators</p>
                  <p className="text-xs text-slate-300">Set up feedback walks and capture insights for the beta.</p>
                </div>
              </li>
            </ul>
          </div>

          <div className="rounded-3xl border border-white/10 bg-gradient-to-br from-sky-400/30 via-sky-500/20 to-indigo-500/40 p-6 shadow-[0_25px_60px_-20px_rgba(14,116,144,0.6)] backdrop-blur">
            <h3 className="text-base font-semibold text-white">Need inspiration?</h3>
            <p className="mt-2 text-sm text-slate-100">
              Host a walking lab with your favorite photographers and collect the rituals
              that make every outing memorable. Use their stories to inspire the new
              roadmap.
            </p>
            <a
              href="mailto:team@photowalk.app"
              className="mt-6 inline-flex items-center rounded-full bg-white px-5 py-2 text-sm font-semibold text-slate-900 shadow transition hover:-translate-y-0.5 hover:bg-slate-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white"
            >
              Connect with the team
            </a>
          </div>
        </aside>
      </div>
    </div>
  );
}

export const Route = createFileRoute('/_app/')({
  component: DashboardLanding,
});
