#import "@preview/cetz:0.4.2": canvas, draw
#import "@preview/cetz-plot:0.1.3": plot

#let data = json("results.json")
#let A = data.a
#let C = data.c
#let MC = data.mc

// ---------- оформление ----------
#set page(
  paper: "a4",
  margin: (x: 2cm, y: 2.2cm),
  numbering: "1",
  header: context {
    if counter(page).get().first() > 1 [
      #set text(9pt)
      Задача 5. Финансовая устойчивость банка
      #h(1fr)
      Формула Бернулли и её приближения
      #place(bottom, dy: 0.4em, line(length: 100%, stroke: 0.5pt))
    ]
  },
)
#set text(lang: "ru", size: 11pt)
#set par(justify: true, leading: 0.62em)
#set heading(numbering: "1.1")
#set math.equation(numbering: "(1)")
#show heading.where(level: 1): set block(above: 1.6em, below: 0.9em)
#show heading.where(level: 2): set block(above: 1.3em, below: 0.7em)
#show table.cell.where(y: 0): strong
#show figure.caption: set text(size: 9.5pt)
#show raw.where(block: true): set text(size: 7.8pt)
#set table(stroke: 0.5pt + luma(60%), inset: 5pt)

// ---------- форматирование чисел ----------
#let pad(s, d) = {
  let parts = s.split(".")
  let frac = if parts.len() > 1 { parts.at(1) } else { "" }
  while frac.len() < d { frac += "0" }
  parts.at(0) + (if d > 0 { "." + frac } else { "" })
}
#let fixed(x, d) = pad(str(calc.round(x, digits: d)), d)
#let sci(x, d: 3) = {
  let e = calc.floor(calc.log(x, base: 10))
  let m = calc.round(x / calc.pow(10.0, e), digits: d - 1)
  if m >= 10 {
    m = m / 10
    e += 1
  }
  box($#fixed(m, d - 1) dot 10^(#e)$)
}
// вероятность: обычная запись, если >= 0.01, иначе научная
#let pr(x, d: 3) = if x >= 0.01 { fixed(x, 4) } else { sci(x, d: d) }
#let pct(x, d: auto) = {
  let v = x * 100
  let dd = if d == auto { if calc.abs(v) >= 100 { 0 } else { 1 } } else { d }
  (if v < 0 { "−" } else { "+" }) + fixed(calc.abs(v), dd) + "%"
}
#let times(x) = {
  if x >= 100 { str(calc.round(x)) } else if x >= 10 { fixed(x, 0) } else { fixed(x, 1) }
}

#let raz(x) = {
  let r = calc.round(x)
  if calc.abs(x - r) > 0.05 { "раза" } else {
    let k = calc.rem(int(r), 100)
    let u = calc.rem(int(r), 10)
    if k >= 11 and k <= 14 { "раз" } else if u >= 2 and u <= 4 { "раза" } else { "раз" }
  }
}
#let tr(x) = {
  let v = if x >= 10 { calc.round(x) } else { calc.round(x, digits: 1) }
  [#times(x) #raz(v)]
}
#let eq(body) = math.equation(block: true, numbering: "(1)", body)
#let eqref(l) = ref(l, supplement: none)

// ---------- стили графиков ----------
#let c-exact = black
#let c-pois = rgb("#1f6fb4")
#let c-ml0 = rgb("#c8372d")
#let c-ml5 = rgb("#2e8b3d")
#let c-int = luma(55%)
#let s-exact = (stroke: (paint: c-exact, thickness: 1.5pt))
#let s-pois = (stroke: (paint: c-pois, thickness: 1pt, dash: "dashed"))
#let s-ml0 = (stroke: (paint: c-ml0, thickness: 1pt))
#let s-ml5 = (stroke: (paint: c-ml5, thickness: 1.1pt, dash: "dotted"))
#let s-int = (stroke: (paint: c-int, thickness: 1pt, dash: "dash-dotted"))
#let ser(rows, xk, yk) = rows.map(r => (r.at(xk), r.at(yk))).filter(p => p.at(1) > 0)
#let lg(rows, xk, yk) = rows.filter(r => r.at(yk) > 0).map(r => (r.at(xk), calc.log(r.at(yk), base: 10)))
#let logfmt = v => $10^(#calc.round(v))$
#let small(body) = {
  set text(size: 8pt)
  body
}

// =====================================================================
#align(center)[
  #text(17pt, weight: "bold")[Финансовая устойчивость банка]\
  #v(2pt)
  #text(12pt)[Точная формула Бернулли и приближения Пуассона и Муавра-Лапласа]
]

#v(0.6em)

Задачи отчёта:

+ Сравнить вероятность массового события, вычисленную по точной формуле Бернулли, с вероятностями по приближённым формулам Пуассона и Муавра-Лапласа.
+ Оценить, как вероятность события меняется при изменении входных данных.

Условие (задача 5). Банк выдал $n = 500$ кредитов, вероятность невозврата каждого кредита $p = 0.02$. Банк остаётся устойчивым, если дефолтов не больше 20. (a) Найти вероятность того, что банк окажется в кризисном состоянии. (b) Сравнить результат с приближениями Пуассона и Муавра-Лапласа и оценить их адекватность. (c) Определить, сколько дефолтов банк должен выдерживать при $n = 1000$, чтобы вероятность осталась прежней.

#heading(level: 1, numbering: none)[Ответы]

#table(
  columns: (auto, 1fr),
  align: (left, left),
  [Пункт], [Результат],
  [(a)], [$P("кризис") = P(X >= 21) = #fixed(A.exact, 7)$, примерно один случай из #calc.round(1 / A.exact).],
  [(b)],
  [Пуассон даёт #fixed(A.poisson, 7) (#pct(A.poisson / A.exact - 1) к точному значению) и годится для оценки риска. Формула Муавра-Лапласа в привычной записи даёт #fixed(A.ml_int, 7) (#pct(A.ml_int / A.exact - 1)), но это совпадение двух противоположных ошибок. Правый хвост, который и есть кризис, она занижает от 2 до 6 раз, поэтому для этой задачи её нельзя считать адекватной.],
  [(c)],
  [При $n = 1000$ банк должен выдерживать до #C.k_le дефолтов включительно (#fixed(C.k_le / C.n * 100, 1)% кредитов). Вероятность кризиса тогда #pr(data.c_rows.at(C.k_le - 28).exact), у исходной задачи #pr(A.exact). Пропорциональный порог 40 даёт избыточный запас.],
)

= Постановка и модель

Банк выдал $n$ кредитов. Каждый не возвращается с вероятностью $p = 0.02$, $q = 1 - p = 0.98$, и кредиты считаются независимыми. Число дефолтов $X$ тогда равно числу успехов в $n$ независимых испытаниях Бернулли: $X tilde "Bin"(n, p)$, и

$ E X = n p, quad D X = n p q. $

Для $n = 500$ получаем $E X = 10$, $D X = 9.8$, $sigma = sqrt(n p q) approx #fixed(A.sigma, 4)$. Банк устойчив при $X <= 20$ и находится в кризисе при $X >= 21$.

Независимость заёмщиков принята как допущение модели. В реальности дефолты зависят от общей экономической ситуации. Положительная корреляция увеличивает разброс числа дефолтов и утяжеляет правый хвост, так что вероятность кризиса в такой модели оказалась бы выше полученной ниже.

= Используемые формулы

== Формула Бернулли

Вероятность ровно $k$ дефолтов:

$ P_n (k) = binom(n, k) p^k q^(n-k), quad k = 0, 1, dots, n. $ <eq-bern>

Это точный результат модели, остальные формулы его приближают.

== Теорема Пуассона

Если $n -> infinity$, $p -> 0$ и $n p -> lambda$, то

$ P_n (k) -> lambda^k / k! e^(-lambda). $ <eq-pois>

На практике приближением пользуются при $p lt.eq 0.1$ и $lambda = n p lt.eq 10$. У распределения Пуассона математическое ожидание и дисперсия оба равны $lambda$, а у биномиального дисперсия $n p q = lambda (1 - p)$ чуть меньше. Значит, Пуассон приписывает величине немного больший разброс, чем есть на самом деле.

Для погрешности известна оценка Ле Кама: для любого события $A$ разность вероятностей по Бернулли и по Пуассону не больше $n p^2$.

== Теоремы Муавра-Лапласа

Обозначим $x_k = (k - n p) / sqrt(n p q)$, $phi(x) = e^(-x^2 slash 2) / sqrt(2 pi)$ и $Phi(x) = integral_(-infinity)^x phi(t) dif t$. Локальная теорема:

$ P_n (k) approx 1 / sqrt(n p q) phi(x_k). $ <eq-loc>

Интегральная теорема:

$ P(k_1 <= X <= k_2) approx Phi(x_(k_2)) - Phi(x_(k_1)). $ <eq-int>

Здесь $Phi$ это функция распределения стандартного нормального закона. Она связана с функцией Лапласа $Phi_0 (x) = 1 / sqrt(2 pi) integral_0^x e^(-t^2 slash 2) dif t$ из учебных таблиц равенством $Phi(x) = 1/2 + Phi_0 (x)$. В расчётах значения $Phi$ берутся через функцию ошибок `erf`, они совпадают с табличными.

Обычное условие применимости: $n p q gt.eq 10$ (в некоторых учебниках 9). Для $n = 500$ имеем $n p q = 9.8$, то есть граница.

Столбец гистограммы для значения $k$ занимает отрезок $[k - 1/2, k + 1/2]$, поэтому при замене суммы интегралом разумна поправка на дискретность: $P(X <= m) approx Phi((m + 1/2 - n p) / sqrt(n p q))$. Ниже поправка применяется как один из вариантов.

== Как измеряется адекватность

Для приближения $tilde(P)$ точного значения $P$ считаются абсолютная погрешность $tilde(P) - P$ и относительная $(tilde(P) - P) / P$. Событие редкое, и банку важен порядок вероятности: значения $0.0004$ и $0.0014$ означают «один случай из 2500» и «один из 700». Поэтому основной мерой берётся относительная погрешность. Для оценки риска приемлемой условно считается погрешность до 20%. Порог выбран в отчёте для определённости.

= Задача 5(a): точная вероятность кризиса

Прямая сумма $sum_(k=21)^(500) P_n (k)$ состоит из 480 слагаемых. Короче перейти к противоположному событию, в нём 21 слагаемое:

$ P(X >= 21) = 1 - sum_(k=0)^(20) binom(500, k) 0.02^k dot 0.98^(500-k). $ <eq-crisis>

Так как $p = 1 slash 50$, каждое слагаемое равно $binom(500, k) dot 49^(500-k) slash 50^500$. Сумма считается в целых числах без округления (функция `tail_exact` в `calc.py`), и только итоговая дробь переводится в десятичную. Результат:

$ P(X <= 20) = #fixed(A.stable, 7), quad P(X >= 21) = #fixed(A.exact, 7) approx #fixed(A.exact * 100, 3)%. $

Кризис наступает примерно в одном случае из #calc.round(1 / A.exact).

== Проверки результата

+ Неравенство Чебышёва. $P(X >= 21) <= P(|X - 10| >= 11) <= D X slash 11^2 = 9.8 slash 121 approx 0.081$. Найденное значение $0.0014$ не противоречит оценке, хотя сама оценка грубая.
+ Моделирование. Для проверки сгенерировано $10^8$ значений $X tilde "Bin"(500, 0.02)$ (10 независимых серий по $10^7$, `numpy.random.default_rng`, `seed = ` #MC.seed). Доля значений $X > 20$ равна #fixed(MC.n500, 7) со стандартной ошибкой $sqrt(hat(p)(1 - hat(p)) slash N) approx #fixed(MC.se500, 7)$. Отклонение от точного значения составляет #fixed((MC.n500 - A.exact) / MC.se500, 2) стандартной ошибки. Средние по выборке: $overline(X) = #fixed(MC.mean500, 4)$ при теоретическом 10, дисперсия #fixed(MC.var500, 3) при теоретической 9.8. Оценки по отдельным сериям лежат между #fixed(calc.min(..MC.batch_est), 7) и #fixed(calc.max(..MC.batch_est), 7).

#v(0.3em)
*Ответ (a):* $P("кризис") = #fixed(A.exact, 7)$.

= Задача 5(b): приближения и их адекватность

== Приближение Пуассона

Параметр $lambda = n p = 10$. По формуле (#eqref(<eq-pois>))

$ P(X >= 21) approx 1 - sum_(k=0)^(20) 10^k / k! e^(-10) = #fixed(A.poisson, 7). $

Абсолютная погрешность #fixed(A.poisson - A.exact, 7), относительная #pct(A.poisson / A.exact - 1). Приближение завышает вероятность, как и следовало ожидать из сравнения дисперсий (10 против 9.8). Условия $p lt.eq 0.1$ и $lambda lt.eq 10$ выполняются, последнее на границе. Оценка Ле Кама даёт $n p^2 = #A.le_cam$, то есть гарантирует погрешность не больше 0.2, что при вероятности порядка $0.001$ ничего не говорит. Адекватность приходится проверять прямым сравнением с точным значением.

== Приближение Муавра-Лапласа

Для границы $k = 20$: $x = (20 - 10) slash #fixed(A.sigma, 4) = #fixed(A.x_hi, 3)$. Для границы $k = 0$ значение симметрично: $x = #fixed(A.x_lo, 3)$.

*Обычный приём.* Вероятность устойчивого события считается по интегральной теореме на отрезке $[0; 20]$:

$ P(0 <= X <= 20) approx Phi(#fixed(A.x_hi, 3)) - Phi(#fixed(A.x_lo, 3)) = 2 Phi(#fixed(A.x_hi, 3)) - 1 = #fixed(A.ml_stable_int, 6). $

Кризис: $1 - #fixed(A.ml_stable_int, 6) = #fixed(A.ml_int, 7)$. Это отличается от точного значения всего на #pct(A.ml_int / A.exact - 1), и на этом месте легко остановиться. Но результат складывается из двух неверных частей:

$ 1 - [Phi(3.194) - Phi(-3.194)] = underbrace((1 - Phi(3.194)), "правый хвост" #fixed(A.ml_s0, 6)) + underbrace(Phi(-3.194), "левый хвост" #fixed(A.left_mass, 6)). $

Левый хвост нормального закона описывает «отрицательное число дефолтов», такого события нет, его вероятность в модели равна нулю. Настоящий кризис это только правый хвост, а он у нормального закона вдвое меньше точного #fixed(A.exact, 6). Ошибки случайно компенсируют друг друга.

*Только событие «кризис».* Событие $X >= 21$ это $21 <= X <= 500$, верхний предел уходит в $+infinity$. Результат зависит от того, какую границу взять:

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (left, right, right, right, right),
    [Граница хвоста], [$x$], [Вероятность], [Отн. погрешность], [Занижение, раз],
    [20 (как у отрезка $[0; 20]$)], [#fixed(A.x_hi, 3)], [#pr(A.ml_s0)], [#pct(A.ml_s0 / A.exact - 1, d: 0)], [#times(A.exact / A.ml_s0)],
    [20.5 (с поправкой)], [#fixed(A.x_s05, 3)], [#pr(A.ml_s05)], [#pct(A.ml_s05 / A.exact - 1, d: 0)], [#times(A.exact / A.ml_s05)],
    [21 (как у отрезка $[21; 500]$)], [#fixed(A.x_s1, 3)], [#pr(A.ml_s1)], [#pct(A.ml_s1 / A.exact - 1, d: 0)], [#times(A.exact / A.ml_s1)],
  ),
  caption: [Правый хвост по интегральной теореме Муавра-Лапласа при $n = 500$, $p = 0.02$.],
)

Три варианта различаются между собой в 3 раза. Если бы приближение хорошо описывало хвост, сдвиг границы на полцелого не менял бы результат так сильно. Во всех вариантах вероятность кризиса занижена минимум вдвое.

== Сравнение по отдельным значениям

Локальная теорема (#eqref(<eq-loc>)) и теорема Пуассона (#eqref(<eq-pois>)) приближают сами вероятности $P_n (k)$. Сравнение с (#eqref(<eq-bern>)) при $n = 500$:

#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto),
    align: (right, right, right, right, right, right),
    [$k$], [Бернулли], [Пуассон], [Отн. погр.], [Муавр-Лаплас], [Отн. погр.],
    ..data.pmf_table.map(r => (
      str(r.k),
      pr(r.exact),
      pr(r.poisson),
      pct(r.poisson / r.exact - 1, d: 0),
      pr(r.local),
      pct(r.local / r.exact - 1, d: 0),
    )).flatten(),
  ),
  caption: [Вероятности $P_{500}(k)$ для $p = 0.02$.],
)

Около среднего ($k = 10$) обе формулы работают: ошибки #pct(data.pmf_table.at(4).poisson / data.pmf_table.at(4).exact - 1) у Пуассона и #pct(data.pmf_table.at(4).local / data.pmf_table.at(4).exact - 1) у Муавра-Лапласа. При удалении от среднего Муавр-Лаплас ошибается в обе стороны: завышает $P(0)$ в #tr(data.pmf_table.at(0).local / data.pmf_table.at(0).exact), потому что нормальная кривая не знает, что $X >= 0$, и занижает значения справа: при $k = 20$ на #pct(data.pmf_table.at(8).local / data.pmf_table.at(8).exact - 1, d: 0), при $k = 30$ примерно в #calc.round(data.pmf_table.at(11).exact / data.pmf_table.at(11).local, digits: -1) раз. Пуассон остаётся ближе: #pct(data.pmf_table.at(8).poisson / data.pmf_table.at(8).exact - 1, d: 0) при $k = 20$ и #pct(data.pmf_table.at(11).poisson / data.pmf_table.at(11).exact - 1, d: 0) при $k = 30$.

#figure(
  {
    small(grid(
      columns: 2,
      gutter: 10pt,
      canvas({
        plot.plot(
          size: (6.6, 5),
          x-label: $k$,
          y-label: $P_(500)(k)$,
          x-min: 0, x-max: 40, y-min: 0, y-max: 0.14,
          x-tick-step: 10, y-tick-step: 0.02,
          legend: "inner-north-east",
          {
            plot.add(ser(data.pmf_curve, "k", "exact"), style: s-exact, label: [Бернулли])
            plot.add(ser(data.pmf_curve, "k", "poisson"), style: s-pois, label: [Пуассон])
            plot.add(ser(data.pmf_curve, "k", "local"), style: s-ml0, label: [Муавр-Лаплас])
          },
        )
      }),
      canvas({
        plot.plot(
          size: (6.6, 5),
          x-label: $k$,
          y-label: [$P_(500)(k)$, лог. шкала],
          x-min: 0, x-max: 40, y-min: -10, y-max: 0, y-format: logfmt,
          x-tick-step: 10, y-tick-step: 2,
          {
            plot.add(lg(data.pmf_curve, "k", "exact"), style: s-exact)
            plot.add(lg(data.pmf_curve, "k", "poisson"), style: s-pois)
            plot.add(lg(data.pmf_curve, "k", "local"), style: s-ml0)
            plot.add(
              range(0, 36).filter(k => MC.hist500.at(k) > 0).map(k => (k, calc.log(MC.hist500.at(k) / MC.trials, base: 10))),
              style: (stroke: none),
              mark: "o", mark-size: 0.09,
              mark-style: (stroke: c-ml5, fill: none),
            )
          },
        )
      }),
    ))
  },
  caption: [Распределение числа дефолтов при $n = 500$, $p = 0.02$. Кружками справа отмечены частоты из моделирования. Справа в логарифмической шкале видно, что хвост Муавра-Лапласа уходит вниз заметно быстрее точного.],
)

== Почему так получается

При $p = 0.02$ распределение несимметрично: среднее 10 лежит близко к нулю, слева значений мало (нельзя иметь меньше 0 дефолтов), справа хвост тянется дальше. Нормальная кривая симметрична. Граница $k = 20$ отстоит от среднего на $3.19 sigma$, и в этой области форма хвоста определяет всё, а симметричная кривая её не передаёт. Сама теорема гарантирует малую абсолютную погрешность функции распределения: здесь она порядка $10^(-3)$. Но вероятность кризиса тоже порядка $10^(-3)$, поэтому относительная погрешность оказывается большой. Пуассон несимметричен и поэтому лучше описывает форму хвоста, а его завышение объясняется разницей дисперсий.

== Итог по задаче (b)

#figure(
  table(
    columns: (1fr, auto, auto, auto),
    align: (left, right, right, right),
    [Способ], [$P("кризис")$], [Абс. погрешность], [Отн. погрешность],
    [Формула Бернулли (точно)], [#fixed(A.exact, 7)], [0], [0],
    [Пуассон, $lambda = 10$], [#fixed(A.poisson, 7)], [#fixed(A.poisson - A.exact, 7)], [#pct(A.poisson / A.exact - 1)],
    [Муавр-Лаплас, отрезок $[0; 20]$], [#fixed(A.ml_int, 7)], [#fixed(A.ml_int - A.exact, 7)], [#pct(A.ml_int / A.exact - 1)],
    [Муавр-Лаплас, хвост от 20], [#fixed(A.ml_s0, 7)], [#fixed(A.ml_s0 - A.exact, 7)], [#pct(A.ml_s0 / A.exact - 1)],
    [Муавр-Лаплас, хвост от 20.5], [#fixed(A.ml_s05, 7)], [#fixed(A.ml_s05 - A.exact, 7)], [#pct(A.ml_s05 / A.exact - 1)],
    [Муавр-Лаплас, хвост от 21], [#fixed(A.ml_s1, 7)], [#fixed(A.ml_s1 - A.exact, 7)], [#pct(A.ml_s1 / A.exact - 1)],
  ),
  caption: [Вероятность кризиса при $n = 500$.],
)

Приближение Пуассона адекватно: ошибка #pct(A.poisson / A.exact - 1) укладывается в принятые 20%, и она в безопасную сторону, риск немного завышается. Приближение Муавра-Лапласа для этой задачи неадекватно. Близкое совпадение в обычной записи случайно: вклад нереального левого хвоста компенсирует занижение правого. Это подтверждается в разделе 6: при другом пороге компенсации нет.

= Задача 5(c): порог для $n = 1000$

При $n = 1000$ имеем $E X = 20$, $D X = 19.6$, $sigma = #fixed(C.sigma, 4)$. Нужно найти $m$, при котором $P(X > m)$ совпадает с исходным $#fixed(C.target, 7)$.

Значения $P(X > m)$ при целых $m$ образуют дискретный ряд, точного равенства не будет. Поэтому ищется наименьшее $m$, при котором вероятность кризиса не превышает исходную. Таблица точных значений по формуле Бернулли:

#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    align: (right, right, right, right, right),
    [$m$], [Бернулли], [Бернулли / исходная], [Пуассон, $lambda = 20$], [Муавр-Лаплас, хвост от $m$],
    ..data.c_rows.filter(r => r.k >= 32 and r.k <= 37).map(r => (
      str(r.k),
      pr(r.exact),
      fixed(r.exact / C.target, 2),
      pr(r.poisson),
      pr(r.ml_s0),
    )).flatten(),
  ),
  caption: [Вероятность $P(X > m)$ при $n = 1000$, исходная вероятность для сравнения: #pr(C.target).],
)

При $m = 33$ вероятность в #fixed(C.ratio_below, 2) раза выше исходной, при $m = 34$ составляет #fixed(C.ratio_le, 3) от исходной. Значит, наименьший подходящий порог равен *#C.k_le*, и он же даёт ближайшее значение. Проверка моделированием ($N = 10^8$): $P(X > 34) approx #fixed(MC.n1000.at("34"), 7)$ при точном #fixed(data.c_rows.at(6).exact, 7); $P(X > 33) approx #fixed(MC.n1000.at("33"), 7)$ при точном #fixed(data.c_rows.at(5).exact, 7).

== Оценка без перебора

Условие «вероятность прежняя» означает, что отступ порога от среднего, измеренный в $sigma$, остаётся прежним (по интегральной теореме вероятность зависит от $(m - n p) slash sigma$). При $n = 500$ он равен $z = (20 - 10) slash #fixed(A.sigma, 4) = #fixed(C.z0, 3)$. При $n = 1000$ получаем

$ m approx n p + z sigma = 20 + #fixed(C.z0, 3) dot #fixed(C.sigma, 4) = #fixed(C.m_s0, 2). $

То же самое проще: $sigma$ выросла в $sqrt(2)$ раз, поэтому отступ от среднего вырос с 10 до $10 sqrt(2) approx 14.14$. Оценка #fixed(C.m_s0, 2) согласуется с точным ответом 34. Хотя Муавр-Лаплас занижает сами вероятности, при переносе порога с $n = 500$ на $n = 1000$ ошибка приблизительно сохраняется (отношение точного к приближённому 2.0 и 1.7) и в основном сокращается. Приближение Пуассона с $lambda = 20$ даёт $P(Y > 34) = #pr(data.c_rows.at(6).poisson)$, это больше исходной вероятности, так что по Пуассону получилось бы #C.k_poisson.

== Почему не 40

Если рассуждать пропорционально («500 кредитов и 20 дефолтов, значит 1000 и 40»), получится порог 40. При нём $P(X > 40) = #pr(data.c_rows.at(12).exact)$, то есть в #tr(C.target / data.c_rows.at(12).exact) меньше исходной вероятности. Банк держал бы резерв, которого вероятностные требования не требуют. Разброс числа дефолтов растёт как $sqrt(n)$, а не как $n$, поэтому с ростом портфеля относительный запас можно уменьшать: 4% при $n = 500$ и #fixed(C.k_le / C.n * 100, 1)% при $n = 1000$.

*Ответ (c):* при $n = 1000$ банк должен выдерживать #C.k_le дефолтов.

= Динамика вероятности при изменении входных данных

Вероятность кризиса $P(X > m)$ зависит от трёх величин: порога $m$, вероятности дефолта $p$ и числа кредитов $n$. Ниже меняется одна из них, остальные фиксированы на значениях задачи ($n = 500$, $p = 0.02$, $m = 20$), если не сказано иное. Все числа получены из `calc.py` (блоки `dyn_*`). Приближённые значения Муавра-Лапласа даны в двух вариантах: хвост от $m$ и хвост от $m + 1/2$, обозначены ML и ML(±½).

== Порог m

#figure(
  {
    small(canvas({
      plot.plot(
        size: (11, 5.6),
        x-label: [порог $m$],
        y-label: [$P(X > m)$, лог. шкала],
        x-min: 8, x-max: 35, y-min: -10, y-max: 0, y-format: logfmt,
        x-tick-step: 5, y-tick-step: 2,
        legend: "inner-north-east",
        {
          plot.add(lg(data.dyn_m, "m", "exact"), style: s-exact, label: [Бернулли])
          plot.add(lg(data.dyn_m, "m", "poisson"), style: s-pois, label: [Пуассон])
          plot.add(lg(data.dyn_m, "m", "ml_s0"), style: s-ml0, label: [ML, хвост от $m$])
          plot.add(lg(data.dyn_m, "m", "ml_s05"), style: s-ml5, label: [ML(±½)])
          plot.add(lg(data.dyn_m, "m", "ml_int"), style: s-int, label: [ML, отрезок $[0; m]$])
          plot.add-vline(20, style: (stroke: (paint: luma(70%), dash: "dotted")))
        },
      )
    }))
  },
  caption: [Вероятность кризиса в зависимости от порога при $n = 500$, $p = 0.02$.],
)

#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto),
    align: (right, right, right, right, right, right),
    [$m$], [Бернулли], [Пуассон], [ML, отрезок $[0; m]$], [ML, хвост от $m$], [ML(±½)],
    ..data.dyn_m.filter(r => (12, 15, 18, 20, 22, 25, 28, 30, 35).contains(r.m)).map(r => (
      str(r.m),
      pr(r.exact),
      pr(r.poisson),
      pr(r.ml_int),
      pr(r.ml_s0),
      pr(r.ml_s05),
    )).flatten(),
  ),
  caption: [Вероятность $P(X > m)$ при $n = 500$, $p = 0.02$.],
)

Каждый дополнительный допустимый дефолт уменьшает вероятность кризиса примерно в 2.3 раза около $m = 20$ (отношение $P(X > 21) slash P(X > 20) = #fixed(data.dyn_m.at(13).exact / data.dyn_m.at(12).exact, 3)$). Между $m = 15$ и $m = 25$ вероятность падает с #pr(data.dyn_m.at(7).exact) до #pr(data.dyn_m.at(17).exact), то есть примерно в #calc.round(data.dyn_m.at(7).exact / data.dyn_m.at(17).exact, digits: -1) раз.

Качество приближений зависит от порога:

- Пуассон завышает вероятность, и завышение растёт с $m$: от #pct(data.dyn_m.at(4).poisson / data.dyn_m.at(4).exact - 1) при $m = 12$ до #pct(data.dyn_m.at(22).poisson / data.dyn_m.at(22).exact - 1, d: 0) при $m = 30$ (в #fixed(data.dyn_m.at(22).poisson / data.dyn_m.at(22).exact, 1) раза). Рост в сторону запаса, но при $m gt.eq 25$ вероятность уже порядка $10^(-5)$.
- В центре ($m = 12$, вероятность около 0.2) ML(±½) отличается от точного на #pct(data.dyn_m.at(4).ml_s05 / data.dyn_m.at(4).exact - 1). В хвосте ошибки быстро растут: при $m = 25$ точное значение больше ML в #tr(data.dyn_m.at(17).exact / data.dyn_m.at(17).ml_s0), при $m = 30$ в #tr(data.dyn_m.at(22).exact / data.dyn_m.at(22).ml_s0).
- Приём с отрезком $[0; m]$ даёт верный порядок только около $m = 20$. Левый хвост добавляет константу #fixed(A.left_mass, 6), поэтому при $m gt.eq 22$ оценка перестаёт убывать: при $m = 25$ она больше точной в #tr(data.dyn_m.at(17).ml_int / data.dyn_m.at(17).exact), при $m = 30$ в #tr(data.dyn_m.at(22).ml_int / data.dyn_m.at(22).exact). Это прямое подтверждение того, что совпадение в пункте (b) случайно.

== Вероятность дефолта p и число кредитов n

#figure(
  {
    small(grid(
      columns: 2,
      gutter: 10pt,
      canvas({
        plot.plot(
          size: (6.6, 5),
          x-label: [$p$],
          y-label: [$P(X > 20)$],
          x-min: 0.01, x-max: 0.06, y-min: 0, y-max: 1,
          x-tick-step: 0.01, y-tick-step: 0.2,
          legend: "inner-south-east",
          {
            plot.add(ser(data.dyn_p, "p", "exact"), style: s-exact, label: [Бернулли])
            plot.add(ser(data.dyn_p, "p", "poisson"), style: s-pois, label: [Пуассон])
            plot.add(ser(data.dyn_p, "p", "ml_s05"), style: s-ml5, label: [ML(±½)])
            plot.add(ser(data.dyn_p, "p", "ml_s0"), style: s-ml0, label: [ML])
          },
        )
      }),
      canvas({
        plot.plot(
          size: (6.6, 5),
          x-label: [$n$],
          y-label: [$P(X > 20)$],
          x-min: 100, x-max: 1500, y-min: 0, y-max: 1,
          x-tick-step: 300, y-tick-step: 0.2,
          legend: "inner-south-east",
          {
            plot.add(ser(data.dyn_n_fixed, "n", "exact"), style: s-exact, label: [Бернулли])
            plot.add(ser(data.dyn_n_fixed, "n", "poisson"), style: s-pois, label: [Пуассон])
            plot.add(ser(data.dyn_n_fixed, "n", "ml_s05"), style: s-ml5, label: [ML(±½)])
            plot.add(ser(data.dyn_n_fixed, "n", "ml_s0"), style: s-ml0, label: [ML])
          },
        )
      }),
    ))
  },
  caption: [Слева: зависимость от $p$ при $n = 500$, $m = 20$. Справа: зависимость от $n$ при $p = 0.02$, $m = 20$.],
)

#let wantp = (0.01, 0.014, 0.018, 0.02, 0.022, 0.026, 0.03, 0.04, 0.05, 0.06)
#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto),
    align: (right, right, right, right, right, right),
    [$p$], [$lambda = 500 p$], [Бернулли], [Пуассон], [ML], [ML(±½)],
    ..data.dyn_p.filter(r => wantp.contains(calc.round(r.p, digits: 3))).map(r => (
      fixed(r.p, 3),
      fixed(500 * r.p, 0),
      pr(r.exact),
      pr(r.poisson),
      pr(r.ml_s0),
      pr(r.ml_s05),
    )).flatten(),
  ),
  caption: [$P(X > 20)$ при $n = 500$ в зависимости от вероятности дефолта $p$.],
)

*Зависимость от p.* Вероятность кризиса очень чувствительна к $p$. Рост $p$ с 0.02 до 0.03 увеличивает её в #tr(data.dyn_p.at(10).exact / A.exact), до 0.04 в #tr(data.dyn_p.at(15).exact / A.exact). При $p = 0.04$ порог 20 совпадает со средним $n p$, и вероятность равна #fixed(data.dyn_p.at(15).exact, 3). При $p = 0.01$ вероятность падает до #pr(data.dyn_p.at(0).exact). Поэтому ошибка в оценке $p$ на один процентный пункт меняет вывод о рискованности портфеля на порядки.

С ростом $p$ приближения улучшаются. При $p gt.eq 0.03$ (вероятность кризиса выше 0.08) Пуассон ошибается не более чем на #fixed((data.dyn_p.at(10).poisson / data.dyn_p.at(10).exact - 1) * 100, 0)%, а при $p = 0.04$ практически совпадает с точным значением. ML(±½) в этой области даёт ошибку #pct(data.dyn_p.at(10).ml_s05 / data.dyn_p.at(10).exact - 1, d: 0) при $p = 0.03$ и #pct(data.dyn_p.at(15).ml_s05 / data.dyn_p.at(15).exact - 1, d: 0) при $p = 0.04$. При малых вероятностях ML занижает риск сильно: в #tr(data.dyn_p.at(3).exact / data.dyn_p.at(3).ml_s0) при $p = 0.016$ и в #tr(data.dyn_p.at(2).exact / data.dyn_p.at(2).ml_s0) при $p = 0.014$.

#let wantn = (100, 300, 500, 700, 1000, 1500)
#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto),
    align: (right, right, right, right, right, right),
    [$n$], [$lambda = 0.02 n$], [Бернулли], [Пуассон], [ML], [ML(±½)],
    ..data.dyn_n_fixed.filter(r => wantn.contains(r.n)).map(r => (
      str(r.n),
      fixed(0.02 * r.n, 0),
      pr(r.exact),
      pr(r.poisson),
      pr(r.ml_s0),
      pr(r.ml_s05),
    )).flatten(),
  ),
  caption: [$P(X > 20)$ при $p = 0.02$ в зависимости от числа кредитов $n$.],
)

*Зависимость от n при фиксированном пороге.* Если порог 20 остаётся прежним, а портфель растёт, вероятность кризиса резко растёт, потому что растёт среднее $n p$. При $n = 300$ она около $10^(-6)$, при $n = 500$ равна #pr(A.exact), при $n = 1000$ (среднее равно порогу) составляет #fixed(data.dyn_n_fixed.at(18).exact, 3), а при $n = 1500$ достигает #fixed(data.dyn_n_fixed.at(28).exact, 3).

== Порог растёт вместе с портфелем

Рассмотрим две схемы масштабирования. В первой допустимая доля дефолтов остаётся равной 4% ($m = 0.04 n$, вдвое больше ожидаемых 2%).

#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto, auto, auto),
    align: (right, right, right, right, right, right, right, right),
    [$n$], [$m$], [Бернулли], [Пуассон], [П / Б], [ML], [ML / Б], [ML(±½) / Б],
    ..data.dyn_n_prop.map(r => (
      str(r.n),
      str(r.m),
      pr(r.exact),
      pr(r.poisson),
      fixed(r.r_poisson, 2),
      pr(r.ml_s0),
      if r.r_ml0 >= 0.01 { fixed(r.r_ml0, 2) } else { sci(r.r_ml0, d: 1) },
      if r.r_ml05 >= 0.01 { fixed(r.r_ml05, 2) } else { sci(r.r_ml05, d: 1) },
    )).flatten(),
  ),
  caption: [Порог $m = 0.04 n$ при $p = 0.02$. Б: точное значение по Бернулли, П: Пуассон. Столбцы «/ Б» это отношение приближённого значения к точному.],
)

#figure(
  {
    small(grid(
      columns: 2,
      gutter: 10pt,
      canvas({
        plot.plot(
          size: (6.6, 5),
          x-label: [$n$],
          y-label: [$P(X > 0.04 n)$, лог. шкала],
          x-min: 100, x-max: 3000, y-min: -12, y-max: 0, y-format: logfmt,
          x-tick-step: 500, y-tick-step: 3,
          {
            plot.add(lg(data.dyn_n_prop_curve, "n", "exact"), style: s-exact)
          },
        )
      }),
      canvas({
        plot.plot(
          size: (6.6, 5),
          x-label: [$n$],
          y-label: [приближённое / точное, лог. шкала],
          x-min: 100, x-max: 3000, y-min: -3, y-max: 0.5, y-format: logfmt,
          x-tick-step: 500, y-tick-step: 1,
          legend: "inner-south-west",
          {
            plot.add(lg(data.dyn_n_prop_curve, "n", "r_poisson"), style: s-pois, label: [Пуассон])
            plot.add(lg(data.dyn_n_prop_curve, "n", "r_ml0"), style: s-ml0, label: [ML])
            plot.add(lg(data.dyn_n_prop_curve, "n", "r_ml05"), style: s-ml5, label: [ML(±½)])
            plot.add-hline(0, style: (stroke: (paint: luma(60%), dash: "dotted")))
          },
        )
      }),
    ))
  },
  caption: [Порог $m = 0.04 n$. Слева: точная вероятность. Справа: отношение приближённой вероятности к точной (1 означает точное совпадение).],
)

Вероятность кризиса при пропорциональном пороге быстро убывает: #pr(data.dyn_n_prop.at(0).exact) при $n = 100$, #pr(data.dyn_n_prop.at(3).exact) при $n = 500$, #pr(data.dyn_n_prop.at(5).exact) при $n = 1000$, #pr(data.dyn_n_prop.at(8).exact) при $n = 3000$. Доля дефолтов $X slash n$ концентрируется около $p = 0.02$ (закон больших чисел), и порог 4% оказывается всё дальше от типичных значений в единицах $sigma$.

Качество приближений при этом меняется по-разному. Отношение Пуассон / Бернулли растёт с #fixed(data.dyn_n_prop.at(0).r_poisson, 2) при $n = 100$ до #fixed(data.dyn_n_prop.at(8).r_poisson, 2) при $n = 3000$: при фиксированном $p$ величина $n p^2$ растёт, и приближение ухудшается, хотя остаётся на стороне запаса. Отношение ML / Бернулли пересекает 1 около $n = 200$ и дальше падает: #fixed(data.dyn_n_prop.at(3).r_ml0, 2) при $n = 500$ и #sci(data.dyn_n_prop.at(8).r_ml0, d: 1) при $n = 3000$. Чем дальше порог в хвосте, тем сильнее занижение.

Во второй схеме порог подбирается так, чтобы вероятность осталась не выше исходной (то есть так, как в пункте (c)).

#figure(
  table(
    columns: (auto, auto, auto, auto, auto, auto),
    align: (right, right, right, right, right, right),
    [$n$], [Минимальный $m$], [Доля $m slash n$], [$n p + z sigma$], [Порог $0.04 n$], [$P(X > m)$],
    ..data.dyn_need.map(r => (
      str(r.n),
      str(r.m),
      fixed(r.share * 100, 2) + "%",
      fixed(r.normal, 1),
      fixed(r.naive, 0),
      pr(r.prob),
    )).flatten(),
  ),
  caption: [Минимальный порог, при котором $P(X > m) <= #pr(A.exact)$ ($p = 0.02$, $z = #fixed(C.z0, 3)$).],
)

#figure(
  {
    small(grid(
      columns: 2,
      gutter: 10pt,
      canvas({
        plot.plot(
          size: (6.6, 5),
          x-label: [$n$],
          y-label: [порог $m$],
          x-min: 0, x-max: 5000, y-min: 0, y-max: 210,
          x-tick-step: 1000, y-tick-step: 50,
          legend: "inner-north-west",
          {
            plot.add(ser(data.dyn_need, "n", "m"), style: (stroke: none), mark: "o", mark-size: 0.14,
              mark-style: (stroke: c-exact, fill: c-exact), label: [точный минимум])
            plot.add(ser(data.dyn_need, "n", "normal"), style: s-ml0, label: [$n p + z sigma$])
            plot.add(ser(data.dyn_need, "n", "naive"), style: s-pois, label: [$0.04 n$])
          },
        )
      }),
      canvas({
        plot.plot(
          size: (6.6, 5),
          x-label: [$n$],
          y-label: [доля $m slash n$],
          x-min: 0, x-max: 5000, y-min: 0.015, y-max: 0.055,
          x-tick-step: 1000, y-tick-step: 0.01,
          {
            plot.add(data.dyn_need.map(r => (r.n, r.share)), style: s-exact, mark: "o", mark-size: 0.12,
              mark-style: (stroke: c-exact, fill: c-exact))
            plot.add-hline(0.02, style: (stroke: (paint: c-ml0, dash: "dashed")))
          },
        )
      }),
    ))
  },
  caption: [Минимальный порог для сохранения вероятности. Слева: сам порог и две оценки. Справа: доля порога в числе кредитов; пунктир отмечает $p = 0.02$.],
)

Нужный порог растёт примерно как $n p + z sqrt(n p q)$: линейный член даёт среднее, добавка растёт как $sqrt(n)$. Оценка $n p + z sigma$ отличается от точного минимума менее чем на единицу (максимум #fixed(calc.max(..data.dyn_need.map(r => calc.abs(r.m - r.normal))), 2)). Нужная доля $m slash n$ убывает с #fixed(data.dyn_need.at(0).share * 100, 1)% при $n = 250$ до #fixed(data.dyn_need.at(8).share * 100, 2)% при $n = 5000$ и стремится к $p = 2%$ сверху. Пропорциональное правило 4% при $n = 5000$ даёт порог #data.dyn_need.at(8).naive вместо #data.dyn_need.at(8).m, то есть #pct(data.dyn_need.at(8).naive / data.dyn_need.at(8).m - 1, d: 0) избыточного запаса.

= Выводы

+ Вероятность кризиса при $n = 500$, $p = 0.02$, пороге 20 равна #fixed(A.exact, 7). Моделирование в $10^8$ испытаний подтверждает её, стандартная ошибка оценки #fixed(MC.se500, 7).
+ Приближение Пуассона даёт #fixed(A.poisson, 7) (#pct(A.poisson / A.exact - 1)). Оно адекватно в области, где поставлена задача. При вероятностях кризиса ниже 0.4 во всех расчётах оно завышает риск, то есть ошибается в сторону запаса. При фиксированном $p$ его точность падает с ростом $n$ и удалением порога в хвост (отношение к точному значению до 1.9 при $n = 3000$), при $p gt.eq 0.03$ ошибка не больше 4%.
+ Приближение Муавра-Лапласа адекватно около центра распределения и при вероятностях порядка $0.1$ и выше (в варианте с поправкой ½ ошибка 6% при $p = 0.03$). В хвосте с вероятностью порядка $10^(-3)$ и меньше оно занижает риск от 2 до 6 раз при $n = 500$ и сильнее при больших $n$. Близкое значение #fixed(A.ml_int, 6) по стандартному приёму случайно: оно складывается из заниженного правого хвоста и нереального левого.
+ Вероятность кризиса сильнее всего зависит от $p$ (рост в #tr(data.dyn_p.at(10).exact / A.exact) при $p$ от 0.02 до 0.03), затем от $n$ при фиксированном пороге, и слабее всего от порога (в 2.3 раза на одну единицу вблизи $m = 20$).
+ Чтобы сохранить вероятность при удвоении портфеля, отступ порога от среднего нужно увеличить в $sqrt(2)$ раз, а не вдвое: при $n = 1000$ порог равен #C.k_le дефолтам (#fixed(C.k_le / C.n * 100, 1)% кредитов). Пропорциональный порог 40 даёт избыточный запас.

= Исходники и воспроизведение

Все числа и графики отчёта получены автоматически из трёх файлов, лежащих рядом с отчётом:

- #link("calc.py")[`calc.py`]: расчёты и моделирование (полный текст в приложении). Запуск: `python3 calc.py`. Использовались Python 3.9.6 и numpy 2.0.2. Генератор `default_rng` с заданным `seed` воспроизводит числа моделирования на той же версии numpy, на другой версии они могут немного отличаться. Время работы около 15 секунд.
- #link("results.json")[`results.json`]: результат работы `calc.py`, из него отчёт берёт все числа и точки графиков.
- #link("report.typ")[`report.typ`]: исходник отчёта. Сборка: `typst compile report.typ`.

Где в коде находится каждое вычисление:

#table(
  columns: (auto, 1fr),
  align: (left, left),
  [Что], [Функция или блок `calc.py`],
  [Формула Бернулли (#eqref(<eq-bern>)), точный хвост (#eqref(<eq-crisis>))], [`pmf_exact`, `tail_exact`: целочисленная арифметика, `fractions.Fraction`],
  [Пуассон (#eqref(<eq-pois>))], [`pmf_poisson`, `tail_poisson`],
  [Муавр-Лаплас (#eqref(<eq-loc>)), (#eqref(<eq-int>))], [`ml_local`, `ml_tail` (граница $m$, $m + 1/2$, $m + 1$), `ml_interval_crisis` (отрезок $[0; m]$)],
  [Функции $Phi$, $phi$], [`Phi`, `phi`: через `math.erf`, `math.erfc`],
  [Пункты (a), (b)], [блок «(a), (b): n = 500, m = 20» (`out["a"]`, `out["pmf_table"]`)],
  [Пункт (c)], [блок «(c): n = 1000» (`out["c"]`, `out["c_rows"]`)],
  [Динамика], [блок «динамика» (`dyn_m`, `dyn_p`, `dyn_n_fixed`, `dyn_n_prop`, `dyn_need`)],
  [Моделирование], [блок «Монте-Карло»: `numpy.random.default_rng`, `Generator.binomial`, 10 серий по $10^7$],
)

#pagebreak(weak: true)
= Приложение: текст calc.py <app-code>

#raw(read("calc.py"), lang: "python", block: true)
