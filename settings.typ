#import "@preview/cetz:0.4.2": canvas, draw
#import "@preview/cetz-plot:0.1.3": plot

#let data = json("results.json")
#let A = data.a
#let C = data.c
#let MC = data.mc

// ---------- оформление ----------
#let apply-style(body) = {
    set page(
        paper: "a4",
        margin: (x: 2cm, y: 2.2cm),
        numbering: "1",
    )

    set text(lang: "ru", size: 11pt)
    set par(justify: true, leading: 0.62em)
    set heading(numbering: "1.1")
    set math.equation(numbering: "(1)")

    show heading.where(level: 1): set block(
        above: 1.6em,
        below: 0.9em,
    )

    show heading.where(level: 2): set block(
        above: 1.3em,
        below: 0.7em,
    )

    show table.cell.where(y: 0): strong
    show figure.caption: set text(size: 9.5pt)
    show raw.where(block: true): set text(size: 7.8pt)

    set table(
        stroke: 0.5pt + luma(60%),
        inset: 5pt,
    )

    body
}

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
