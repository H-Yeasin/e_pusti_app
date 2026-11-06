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
