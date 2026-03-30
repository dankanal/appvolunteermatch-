import { motion } from "framer-motion";

export default function VolunteerMatchSite() {
  const features = [
    {
      title: "Быстрые заявки",
      text: "Создавайте запросы на помощь за пару минут и находите волонтёров рядом.",
      icon: "📝",
    },
    {
      title: "Чат внутри приложения",
      text: "Общайтесь безопасно и удобно прямо после отклика на заявку.",
      icon: "💬",
    },
    {
      title: "Помощь рядом",
      text: "Лента ближайших заявок помогает быстро находить тех, кому нужна поддержка.",
      icon: "📍",
    },
    {
      title: "Рейтинг и достижения",
      text: "Повышайте доверие в сообществе благодаря отзывам и полезной активности.",
      icon: "🏆",
    },
  ];

  const steps = [
    {
      n: "01",
      title: "Создай заявку",
      text: "Опиши, какая помощь нужна: еда, лекарства, техника, учёба или просто поддержка.",
    },
    {
      n: "02",
      title: "Найди отклик",
      text: "Волонтёр рядом увидит заявку, откликнется и откроет чат.",
    },
    {
      n: "03",
      title: "Получи помощь",
      text: "Обсудите детали, завершите заявку и оставьте оценку после помощи.",
    },
  ];

  const stats = [
    { value: "Рядом", label: "помощь поблизости" },
    { value: "Безопасно", label: "чат и рейтинг" },
    { value: "Быстро", label: "удобные отклики" },
  ];

  const leaves = Array.from({ length: 22 }, (_, i) => ({
    id: i,
    left: `${(i * 5) % 100}%`,
    duration: 9 + (i % 6) * 1.8,
    delay: i * 0.45,
    size: 18 + (i % 5) * 7,
    sway: 20 + (i % 4) * 10,
    rotateMax: 25 + (i % 5) * 8,
  }));

  return (
    <div className="min-h-screen bg-gradient-to-b from-lime-50 via-white to-green-50 text-slate-900">
      <header className="sticky top-0 z-30 border-b border-black/5 bg-white/80 backdrop-blur">
        <div className="mx-auto flex max-w-7xl items-center justify-between px-6 py-4">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-2xl bg-lime-400 shadow-sm">
              <span className="text-xl">🌿</span>
            </div>
            <div>
              <div className="text-lg font-bold">Volunteer Match</div>
              <div className="text-xs text-slate-500">Помощь рядом, когда она нужна</div>
            </div>
          </div>

          <nav className="hidden items-center gap-6 text-sm text-slate-600 md:flex">
            <a href="#features" className="transition hover:text-slate-900">Возможности</a>
            <a href="#how" className="transition hover:text-slate-900">Как работает</a>
            <a href="#download" className="transition hover:text-slate-900">Скачать</a>
            <a href="#iphone" className="transition hover:text-slate-900">iPhone</a>
            <a href="#contacts" className="transition hover:text-slate-900">Контакты</a>
          </nav>

          <a
            href="/volunteer_match.apk"
            download
            className="rounded-2xl bg-slate-900 px-4 py-2 text-sm font-medium text-white transition hover:scale-[1.02]"
          >
            Скачать APK
          </a>
        </div>
      </header>

      <section className="relative overflow-hidden">
        <div className="pointer-events-none absolute inset-0 overflow-hidden">
          {leaves.map((leaf) => (
            <motion.div
              key={leaf.id}
              className="absolute -top-16 select-none text-green-700/70 drop-shadow-sm"
              style={{ left: leaf.left, fontSize: leaf.size }}
              animate={{
                y: [0, 1100],
                x: [0, leaf.sway, -leaf.sway, leaf.sway / 2, 0],
                rotate: [0, leaf.rotateMax, -leaf.rotateMax, leaf.rotateMax / 2, 0],
                opacity: [0, 0.95, 1, 0.9, 0],
              }}
              transition={{
                duration: leaf.duration,
                delay: leaf.delay,
                repeat: Infinity,
                ease: "linear",
              }}
            >
              🍃
            </motion.div>
          ))}
        </div>

        <div className="absolute inset-0 opacity-40">
          <div className="absolute left-8 top-10 h-28 w-28 rounded-full bg-lime-300 blur-3xl" />
          <div className="absolute right-16 top-24 h-40 w-40 rounded-full bg-green-200 blur-3xl" />
          <div className="absolute bottom-10 left-1/3 h-36 w-36 rounded-full bg-emerald-200 blur-3xl" />
        </div>

        <div className="relative mx-auto grid max-w-7xl gap-10 px-6 py-20 md:grid-cols-2 md:items-center md:py-28">
          <div>
            <div className="mb-4 inline-flex items-center gap-2 rounded-full border border-lime-200 bg-white/80 px-4 py-2 text-sm text-slate-700 shadow-sm">
              <span>✨</span>
              <span>Мобильное приложение для волонтёрской помощи</span>
            </div>

            <h1 className="max-w-xl text-4xl font-black leading-tight md:text-6xl">
              Volunteer Match — помощь людям <span className="text-lime-600">рядом с вами</span>
            </h1>

            <p className="mt-6 max-w-xl text-lg leading-8 text-slate-600">
              Создавайте заявки, находите волонтёров поблизости, общайтесь в чате и
              делайте добрые дела быстрее и удобнее.
            </p>

            <div className="mt-8 flex flex-wrap gap-4">
              <a
                href="/volunteer_match.apk"
                download
                className="rounded-2xl bg-lime-400 px-6 py-3 font-semibold text-slate-900 shadow-lg shadow-lime-200 transition hover:translate-y-[-1px]"
              >
                Скачать Android APK
              </a>
              <a
                href="#iphone"
                className="rounded-2xl border border-slate-200 bg-white px-6 py-3 font-semibold text-slate-700 transition hover:bg-slate-50"
              >
                Открыть для iPhone
              </a>
            </div>

            <div className="mt-10 grid max-w-xl grid-cols-3 gap-4">
              {stats.map((item) => (
                <div key={item.label} className="rounded-2xl border border-black/5 bg-white/70 p-4 shadow-sm backdrop-blur">
                  <div className="text-xl font-black text-slate-900">{item.value}</div>
                  <div className="mt-1 text-sm text-slate-500">{item.label}</div>
                </div>
              ))}
            </div>
          </div>

          <div className="relative">
            <div className="mx-auto w-full max-w-md rounded-[2rem] border border-black/5 bg-white p-4 shadow-2xl shadow-lime-100">
              <div className="rounded-[1.5rem] bg-gradient-to-b from-lime-100 to-white p-4">
                <div className="mb-4 rounded-2xl bg-white p-4 shadow-sm">
                  <div className="flex items-center justify-between">
                    <div>
                      <div className="text-sm text-slate-500">Ближайшая заявка</div>
                      <div className="mt-1 text-lg font-bold">Нужны продукты</div>
                    </div>
                    <span className="rounded-full bg-red-100 px-3 py-1 text-xs font-bold text-red-600">СРОЧНО</span>
                  </div>
                  <div className="mt-3 flex gap-2 text-xs text-slate-500">
                    <span className="rounded-full bg-slate-100 px-3 py-1">📍 1.2 км</span>
                    <span className="rounded-full bg-slate-100 px-3 py-1">⏳ 2 часа</span>
                  </div>
                </div>

                <div className="mb-4 rounded-2xl bg-slate-900 p-4 text-white shadow-sm">
                  <div className="text-sm text-white/70">Чат</div>
                  <div className="mt-3 space-y-3 text-sm">
                    <div className="max-w-[80%] rounded-2xl rounded-bl-md bg-white/10 px-4 py-3">
                      Здравствуйте, я рядом и могу помочь через 20 минут.
                    </div>
                    <div className="ml-auto max-w-[80%] rounded-2xl rounded-br-md bg-lime-400 px-4 py-3 text-slate-900">
                      Спасибо! Напишу адрес в личные сообщения.
                    </div>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div className="rounded-2xl bg-white p-4 shadow-sm">
                    <div className="text-2xl">⭐</div>
                    <div className="mt-2 text-sm text-slate-500">Рейтинг и отзывы</div>
                  </div>
                  <div className="rounded-2xl bg-white p-4 shadow-sm">
                    <div className="text-2xl">🏅</div>
                    <div className="mt-2 text-sm text-slate-500">Достижения и активность</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section id="features" className="mx-auto max-w-7xl px-6 py-20">
        <div className="max-w-2xl">
          <div className="text-sm font-semibold uppercase tracking-[0.2em] text-lime-700">Возможности</div>
          <h2 className="mt-3 text-3xl font-black md:text-4xl">Всё, что нужно для удобной помощи</h2>
        </div>

        <div className="mt-10 grid gap-6 md:grid-cols-2 xl:grid-cols-4">
          {features.map((feature) => (
            <div key={feature.title} className="rounded-3xl border border-black/5 bg-white p-6 shadow-sm transition hover:-translate-y-1 hover:shadow-lg">
              <div className="text-3xl">{feature.icon}</div>
              <h3 className="mt-4 text-xl font-bold">{feature.title}</h3>
              <p className="mt-3 text-sm leading-7 text-slate-600">{feature.text}</p>
            </div>
          ))}
        </div>
      </section>

      <section id="how" className="bg-slate-900 py-20 text-white">
        <div className="mx-auto max-w-7xl px-6">
          <div className="max-w-2xl">
            <div className="text-sm font-semibold uppercase tracking-[0.2em] text-lime-300">Как работает</div>
            <h2 className="mt-3 text-3xl font-black md:text-4xl">Три простых шага</h2>
          </div>

          <div className="mt-10 grid gap-6 md:grid-cols-3">
            {steps.map((step) => (
              <div key={step.n} className="rounded-3xl border border-white/10 bg-white/5 p-6 backdrop-blur-sm">
                <div className="text-4xl font-black text-lime-300">{step.n}</div>
                <h3 className="mt-4 text-xl font-bold">{step.title}</h3>
                <p className="mt-3 text-sm leading-7 text-white/75">{step.text}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section id="download" className="mx-auto max-w-7xl px-6 py-20">
        <div className="rounded-[2rem] bg-lime-400 p-8 shadow-xl shadow-lime-100 md:p-12">
          <div className="grid gap-8 md:grid-cols-2 md:items-center">
            <div>
              <div className="text-sm font-semibold uppercase tracking-[0.2em] text-slate-800/70">Android</div>
              <h2 className="mt-3 text-3xl font-black text-slate-900 md:text-4xl">Скачать APK для Android</h2>
              <p className="mt-4 max-w-xl text-slate-800/80">
                Установите приложение на Android и пользуйтесь всеми функциями Volunteer Match.
              </p>
            </div>

            <div className="flex flex-wrap gap-4 md:justify-end">
              <a
                href="/volunteer_match.apk"
                download
                className="rounded-2xl bg-slate-900 px-6 py-3 font-semibold text-white transition hover:translate-y-[-1px]"
              >
                Скачать APK
              </a>
            </div>
          </div>
        </div>
      </section>

      <section id="iphone" className="mx-auto max-w-7xl px-6 pb-20">
        <div className="rounded-[2rem] border border-black/5 bg-white p-8 shadow-sm md:p-12">
          <div className="grid gap-8 md:grid-cols-2 md:items-center">
            <div>
              <div className="text-sm font-semibold uppercase tracking-[0.2em] text-lime-700">iPhone</div>
              <h2 className="mt-3 text-3xl font-black md:text-4xl">
                Откройте Volunteer Match на iPhone
              </h2>
              <p className="mt-4 text-base leading-8 text-slate-600">
                Для iPhone приложение сейчас доступно как веб-версия. Откройте сайт в Safari,
                затем нажмите «Поделиться» и выберите «На экран Домой».
              </p>
            </div>

            <div className="rounded-3xl bg-slate-50 p-6">
              <div className="text-lg font-bold">Как установить на iPhone</div>
              <ol className="mt-4 space-y-3 text-sm leading-7 text-slate-600">
                <li>1. Откройте сайт в Safari</li>
                <li>2. Нажмите кнопку «Поделиться»</li>
                <li>3. Выберите «На экран Домой»</li>
                <li>4. Откройте Volunteer Match как приложение</li>
              </ol>
            </div>
          </div>
        </div>
      </section>

      <section id="about" className="mx-auto max-w-7xl px-6 py-20">
        <div className="grid gap-10 md:grid-cols-2 md:items-center">
          <div>
            <div className="text-sm font-semibold uppercase tracking-[0.2em] text-lime-700">О проекте</div>
            <h2 className="mt-3 text-3xl font-black md:text-4xl">Сервис, который соединяет тех, кому нужна помощь, и тех, кто готов помочь</h2>
            <p className="mt-6 text-base leading-8 text-slate-600">
              Volunteer Match создан как удобное мобильное решение для волонтёрской помощи.
              Здесь можно быстро разместить запрос, откликнуться, пообщаться в чате и безопасно
              завершить помощь через систему оценок и истории активности.
            </p>
          </div>

          <div className="rounded-[2rem] border border-black/5 bg-gradient-to-br from-lime-100 via-white to-green-100 p-8 shadow-sm">
            <div className="rounded-3xl bg-white p-6 shadow-sm">
              <div className="text-lg font-bold">Почему это удобно?</div>
              <ul className="mt-4 space-y-3 text-sm leading-7 text-slate-600">
                <li>• Видно заявки рядом с пользователем</li>
                <li>• Есть чат между участниками</li>
                <li>• Есть рейтинг и история помощи</li>
                <li>• Интерфейс простой и понятный</li>
              </ul>
            </div>
          </div>
        </div>
      </section>

      <section id="contacts" className="mx-auto max-w-7xl px-6 pb-20">
        <div className="rounded-[2rem] border border-black/5 bg-white p-8 shadow-sm md:p-10">
          <div className="max-w-2xl">
            <div className="text-sm font-semibold uppercase tracking-[0.2em] text-lime-700">Контакты</div>
            <h2 className="mt-3 text-3xl font-black md:text-4xl">Есть вопросы или предложения?</h2>
            <p className="mt-4 text-base leading-8 text-slate-600">
              Напишите нам, если хотите узнать больше о проекте, предложить сотрудничество или
              поделиться идеями по развитию Volunteer Match.
            </p>
          </div>

          <div className="mt-8 grid gap-4 md:grid-cols-2">
            <div className="rounded-2xl bg-slate-50 p-5">
              <div className="text-sm text-slate-500">Email</div>
              <div className="mt-2 text-lg font-bold text-slate-900">hello@volunteermatch.app</div>
            </div>
            <div className="rounded-2xl bg-slate-50 p-5">
              <div className="text-sm text-slate-500">Поддержка</div>
              <div className="mt-2 text-lg font-bold text-slate-900">Ответим на ваши вопросы и предложения</div>
            </div>
          </div>
        </div>
      </section>

      <footer className="border-t border-black/5 bg-white/80">
        <div className="mx-auto flex max-w-7xl flex-col gap-3 px-6 py-8 text-sm text-slate-500 md:flex-row md:items-center md:justify-between">
          <div>© 2026 Volunteer Match</div>
          <div>Сделано для добрых дел и помощи рядом</div>
        </div>
      </footer>
    </div>
  );
}