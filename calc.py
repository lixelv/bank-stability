import json
from fractions import Fraction
from math import comb, erf, erfc, exp, lgamma, log, pi, sqrt

import numpy as np

p = 0.02
q = 1 - p
SEED = 20261107
MC_BATCHES = 10
MC_BATCH_SIZE = 10000000


def pmf_exact(n, k):
    return Fraction(comb(n, k) * 49 ** (n - k), 50**n)


def tail_exact(n, m):
    den = 50**n
    cdf = sum(comb(n, k) * 49 ** (n - k) for k in range(m + 1))
    return Fraction(den - cdf, den)


def tail_exact_p(n, m, pp):
    qq = 1 - pp
    return float(1 - sum(comb(n, k) * pp**k * qq ** (n - k) for k in range(m + 1)))


def pmf_poisson(lam, k):
    return exp(-lam + k * log(lam) - lgamma(k + 1))


def tail_poisson(lam, m):
    return sum(pmf_poisson(lam, k) for k in range(m + 1, m + 400))


def Phi(x):
    return 0.5 * (1 + erf(x / sqrt(2)))


def phi(x):
    return exp(-x * x / 2) / sqrt(2 * pi)


def ml_local(n, pp, k):
    mu, s = n * pp, sqrt(n * pp * (1 - pp))
    return phi((k - mu) / s) / s


def ml_tail(n, pp, m, shift):
    mu, s = n * pp, sqrt(n * pp * (1 - pp))
    return 0.5 * erfc(
        (m + shift - mu) / (s * sqrt(2))
    )  # = 1 - Phi(x) без потери точности в хвосте


def ml_interval_crisis(n, pp, m):
    mu, s = n * pp, sqrt(n * pp * (1 - pp))
    return 1 - (Phi((m - mu) / s) - Phi((0 - mu) / s))


out = {}

n, m = 500, 20
lam = n * p
sg = sqrt(n * p * q)
ex = tail_exact(n, m)
out["a"] = dict(
    n=n,
    m=m,
    lam=lam,
    sigma=sg,
    npq=n * p * q,
    exact=float(ex),
    stable=float(1 - ex),
    poisson=tail_poisson(lam, m),
    poisson_stable=1 - tail_poisson(lam, m),
    ml_int=ml_interval_crisis(n, p, m),
    ml_stable_int=1 - ml_interval_crisis(n, p, m),
    ml_s0=ml_tail(n, p, m, 0.0),
    ml_s05=ml_tail(n, p, m, 0.5),
    ml_s1=ml_tail(n, p, m, 1.0),
    x_lo=(0 - lam) / sg,
    x_hi=(m - lam) / sg,
    x_s05=(m + 0.5 - lam) / sg,
    x_s1=(m + 1 - lam) / sg,
    left_mass=Phi((0 - lam) / sg),
    le_cam=n * p * p,
)

ks = [0, 2, 5, 8, 10, 12, 15, 18, 20, 21, 25, 30]
out["pmf_table"] = [
    dict(
        k=k,
        exact=float(pmf_exact(n, k)),
        poisson=pmf_poisson(lam, k),
        local=ml_local(n, p, k),
    )
    for k in ks
]
out["pmf_curve"] = [
    dict(
        k=k,
        exact=float(pmf_exact(n, k)),
        poisson=pmf_poisson(lam, k),
        local=ml_local(n, p, k),
    )
    for k in range(0, 41)
]

n2 = 1000
lam2 = n2 * p
sg2 = sqrt(n2 * p * q)
target = ex
rows = []
for k in range(28, 43):
    rows.append(
        dict(
            k=k,
            exact=float(tail_exact(n2, k)),
            poisson=tail_poisson(lam2, k),
            ml_s0=ml_tail(n2, p, k, 0.0),
            ml_s05=ml_tail(n2, p, k, 0.5),
        )
    )
out["c_rows"] = rows
k_le = next(r["k"] for r in rows if r["exact"] <= float(target))
k_near = min(rows, key=lambda r: abs(r["exact"] - float(target)))["k"]
k_poisson = next(r["k"] for r in rows if r["poisson"] <= float(target))
z0 = (m - lam) / sg
z05 = (m + 0.5 - lam) / sg
out["c"] = dict(
    n=n2,
    lam=lam2,
    sigma=sg2,
    target=float(target),
    z0=z0,
    z05=z05,
    m_s0=lam2 + z0 * sg2,
    m_s05=lam2 + z05 * sg2 - 0.5,
    k_le=k_le,
    k_near=k_near,
    k_poisson=k_poisson,
    naive=40,
    ratio_le=float(tail_exact(n2, k_le) / target),
    ratio_below=float(tail_exact(n2, k_le - 1) / target),
)


out["dyn_m"] = [
    dict(
        m=mm,
        exact=float(tail_exact(500, mm)),
        poisson=tail_poisson(10, mm),
        ml_int=ml_interval_crisis(500, p, mm),
        ml_s0=ml_tail(500, p, mm, 0.0),
        ml_s05=ml_tail(500, p, mm, 0.5),
    )
    for mm in range(8, 36)
]

dyn_p = []
for k in range(10, 61, 2):
    pp = k / 1000
    pf = Fraction(k, 1000)
    dyn_p.append(
        dict(
            p=pp,
            exact=tail_exact_p(500, 20, pf),
            poisson=tail_poisson(500 * pp, 20),
            ml_s0=ml_tail(500, pp, 20, 0.0),
            ml_s05=ml_tail(500, pp, 20, 0.5),
        )
    )
out["dyn_p"] = dyn_p

out["dyn_n_fixed"] = [
    dict(
        n=nn,
        exact=float(tail_exact(nn, 20)),
        poisson=tail_poisson(nn * p, 20),
        ml_s0=ml_tail(nn, p, 20, 0.0),
        ml_s05=ml_tail(nn, p, 20, 0.5),
    )
    for nn in range(100, 1501, 50)
]

prop = []
for nn in [100, 200, 300, 500, 750, 1000, 1500, 2000, 3000]:
    mm = round(0.04 * nn)
    e = float(tail_exact(nn, mm))
    po = tail_poisson(nn * p, mm)
    m0 = ml_tail(nn, p, mm, 0.0)
    m5 = ml_tail(nn, p, mm, 0.5)
    prop.append(
        dict(
            n=nn,
            m=mm,
            exact=e,
            poisson=po,
            ml_s0=m0,
            ml_s05=m5,
            r_poisson=po / e,
            r_ml0=m0 / e,
            r_ml05=m5 / e,
        )
    )
out["dyn_n_prop"] = prop

curve = []
for nn in list(range(100, 1001, 50)) + [1200, 1400, 1600, 1800, 2000, 2500, 3000]:
    mm = round(0.04 * nn)
    e = float(tail_exact(nn, mm))
    curve.append(
        dict(
            n=nn,
            m=mm,
            exact=e,
            r_poisson=tail_poisson(nn * p, mm) / e,
            r_ml0=ml_tail(nn, p, mm, 0.0) / e,
            r_ml05=ml_tail(nn, p, mm, 0.5) / e,
        )
    )
out["dyn_n_prop_curve"] = curve

need = []
for nn in [250, 500, 750, 1000, 1500, 2000, 3000, 4000, 5000]:
    mm = int(nn * p)
    while tail_exact(nn, mm) > target:
        mm += 1
    s_ = sqrt(nn * p * q)
    need.append(
        dict(
            n=nn,
            m=mm,
            normal=nn * p + z0 * s_,
            naive=0.04 * nn,
            share=mm / nn,
            prob=float(tail_exact(nn, mm)),
        )
    )
out["dyn_need"] = need


ss = np.random.SeedSequence(SEED)
hist500 = np.zeros(60, dtype=np.int64)
cnt500 = []
cnt1000 = {k: [] for k in (33, 34, 35, 40)}
sum500 = 0.0
sumsq500 = 0.0
for child in ss.spawn(MC_BATCHES):
    rng = np.random.default_rng(child)
    x = rng.binomial(500, p, size=MC_BATCH_SIZE)
    hist500 += np.bincount(x, minlength=60)[:60]
    cnt500.append(int((x > 20).sum()))
    sum500 += float(x.sum())
    sumsq500 += float((x.astype(np.float64) ** 2).sum())
    y = rng.binomial(1000, p, size=MC_BATCH_SIZE)
    for k in cnt1000:
        cnt1000[k].append(int((y > k).sum()))
N = MC_BATCHES * MC_BATCH_SIZE
est = sum(cnt500) / N
batch_est = [c / MC_BATCH_SIZE for c in cnt500]
se_pool = sqrt(est * (1 - est) / N)
se_batch = float(np.std(batch_est, ddof=1) / sqrt(MC_BATCHES))
mean500 = sum500 / N
var500 = sumsq500 / N - mean500**2
out["mc"] = dict(
    trials=N,
    batches=MC_BATCHES,
    batch_size=MC_BATCH_SIZE,
    seed=SEED,
    n500=est,
    se500=se_pool,
    se500_batches=se_batch,
    batch_est=batch_est,
    mean500=mean500,
    var500=var500,
    hist500=[int(v) for v in hist500[:41]],
    n1000={str(k): sum(v) / N for k, v in cnt1000.items()},
    n1000_se={
        str(k): sqrt((sum(v) / N) * (1 - sum(v) / N) / N) for k, v in cnt1000.items()
    },
)

with open("results.json", "w") as f:
    json.dump(out, f, ensure_ascii=False, indent=1)


a = out["a"]
print("(a) exact crisis =", a["exact"], " stable =", a["stable"])
print(" Poisson =", a["poisson"], " rel", a["poisson"] / a["exact"] - 1)
print(
    " ML interval[0,20]=",
    a["ml_int"],
    " rel",
    a["ml_int"] / a["exact"] - 1,
    ' left mass",
    a["left_mass"],
)
for key in ("ml_s0", "ml_s05", "ml_s1"):
    print("   ", key, a[key], " ratio exact/approx", a["exact"] / a[key])
print("    x:", a["x_lo"], a["x_hi"], a["x_s05"], a["x_s1"], " npq", a["npq"])
mc = out["mc"]
print(
    "MC  p̂ =",
    mc["n500"],
    "se",
    mc["se500"],
    "se_batches",
    mc["se500_batches"],
    " dev(se)",
    (mc["n500"] - a["exact"]) / mc["se500"],
    " mean/var",
    mc["mean500"],
    mc["var500"],
)
print("MC batches", mc["batch_est"])
print("(c)", out["c"])
for r in rows[4:10]:
    print("   ", r)
print("MC n=1000", mc["n1000"], mc["n1000_se"])
for r in need:
    print("need", r)
for r in prop:
    print("prop", {k: (round(v, 3) if k.startswith("r_") else v) for k, v in r.items()})
d = out["dyn_m"]
print(
    "D1 ratios exact P(>m+1)/P(>m):",
    [(d[i]["m"], round(d[i + 1]["exact"] / d[i]["exact"], 3)) for i in range(8, 16)],
)
for r in dyn_p:
    if r["p"] in (0.01, 0.02, 0.03, 0.04, 0.05, 0.06):
        print("D2", r)
for r in out["dyn_n_fixed"]:
    if r["n"] in (100, 300, 500, 1000, 1500):
        print("D3", r)
