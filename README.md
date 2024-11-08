# sf6stats

[![Test](https://github.com/nekorobi/sf6stats/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/nekorobi/sf6stats/actions)

- Show fighting stats of STREET FIGHTER 6

## sf6stats.sh (unofficial Bash script)
- Reference: https://www.streetfighter.com/6/buckler/stats/dia
  - The JSON is downloaded to `$HOME/.cache/sf6stats/`
- `-h, --help`: For more information

### Example
```bash
# Stronger character?
./sf6stats.sh --rank master
```
```text
01 C-terry    54.51%
02 M-terry    53.90%
03 C-honda    51.44%
︙
```

```bash
# Easy fight?
./sf6stats.sh --rank master --chara C-guile
```
```text
58.72% M-dhalsim
57.37% M-ken
56.44% M-gouki
︙
```

## MIT License
- © 2024 Nekorobi
