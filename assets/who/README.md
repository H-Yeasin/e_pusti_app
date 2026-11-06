# WHO reference tables

## `bmi_for_age_2007.csv`

WHO 2007 Growth Reference, **BMI-for-age 5–19 years, z-score expanded
(monthly) tables**, boys and girls combined into one file:

```
sex,month,L,M,S
1,61,-0.7387,15.2641,0.0839
```

- `sex`: 1 = boys, 2 = girls
- `month`: 61–228 (5 y 1 m to 19 y 0 m), 168 rows per sex, 336 rows total
- `L`, `M`, `S`: copied unmodified from the WHO files (only floating-point
  noise from the spreadsheet storage removed by rounding to 6 decimals)

### Source

Downloaded 2026-11-06 from
https://www.who.int/tools/growth-reference-data-for-5to19-years/indicators/bmi-for-age

| File | SHA-256 |
|------|---------|
| `bmi-boys-z-who-2007-exp.xlsx` | `0a60849673f34a06b8e2fe4defe5d00348de687b6c9fce0278f1525fff89eb6d` |
| `bmi-girls-z-who-2007-exp.xlsx` | `66f5c6284b44579ad6135fc639f22c09e36fe5a695b04390377113f6a00deb72` |

### Verification

During conversion, the −2, −1, 0, +1 and +2 SD lines were recomputed from
L, M, S (`M·(1+L·S·z)^(1/L)`) and compared with the SD columns published in
the same WHO files: the largest difference was 0.0005, i.e. the 3-decimal
rounding of the published values. `test/features/who_reference_test.dart`
re-checks a sample of published values on every test run.

Never edit the values by hand. To update, download the WHO files again and
regenerate this CSV.

## WHO 2006 Child Growth Standards (under 5)

Z-score **expanded tables**, boys and girls combined per indicator, same
`sex,<key>,L,M,S` layout:

| File | Indicator | Key |
|------|-----------|-----|
| `wfa_2006.csv` | Weight-for-age | `day` 0–1856 |
| `lhfa_2006.csv` | Length/height-for-age | `day` 0–1856 |
| `wfl_2006.csv` | Weight-for-length (lying, under 2 y) | `length` 45.0–110.0 cm |
| `wfh_2006.csv` | Weight-for-height (standing, 2–5 y) | `height` 65.0–120.0 cm |

Downloaded 2026-11-06 from
https://www.who.int/tools/child-growth-standards/standards (indicator pages
weight-for-age, length-height-for-age, weight-for-length-height).

| File | SHA-256 |
|------|---------|
| `wfa-boys-zscore-expanded-tables.xlsx` | `b5b4748c6bfa5230e2eddafa1767629c349178b08d457f400b59422b8bfef86c` |
| `wfa-girls-zscore-expanded-tables.xlsx` | `ee3ae12cb96c6c5541cdf43665c03ce6c984f877859a183a5f6104eb06a49a6e` |
| `lhfa-boys-zscore-expanded-tables.xlsx` | `c4b1c9029ab9751a5f0888e32f35c7c0287a16d361885cf911ecf23b3f7f6b4f` |
| `lhfa-girls-zscore-expanded-tables.xlsx` | `6aa2876319449a6b1f4d825848128902114ff53c67b92b86a0c5140846013059` |
| `wfl-boys-zscore-expanded-table.xlsx` | `1a6e9a002d2692d038161bc6572a10f8b9fa0657163808141d2981a2132c59cc` |
| `wfl-girls-zscore-expanded-table.xlsx` | `ec116b8e618ad311d34a87231346badf16c75f5c4f82222ec846e05c582bf16a` |
| `wfh-boys-zscore-expanded-tables.xlsx` | `ed3b590f9c65937a138408b13618f33684bb6406a0c56d6a2ce3fd9053a3f59f` |
| `wfh-girls-zscore-expanded-tables.xlsx` | `fca340d5f04aa1556ac410b176b65b290e1b9ff467fc854a97f9b54ad94c9b8a` |

Verified the same way as the 2007 table: the −2…+2 SD lines recomputed from
L, M, S match the SD columns in the WHO files to 0.0005 (their 3-decimal
rounding), for all four indicators. `test/features/who_2006_reference_test.dart`
re-checks published values on every run.
